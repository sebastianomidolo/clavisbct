class SbctItem < ActiveRecord::Base
  # self.primary_keys = [:id_titolo, :library_id, :budget_id]
  self.primary_key = 'id_copia'
  self.table_name='sbct_acquisti.copie'

  attr_accessible :id_titolo, :budget_id, :library_id, :numcopie, :order_date, :order_status, :supplier_id

  before_save :check_record

  
  belongs_to :sbct_title, foreign_key:'id_titolo'
  belongs_to :sbct_budget, foreign_key:'budget_id',include:'clavis_budget'
  belongs_to :sbct_supplier, foreign_key:'supplier_id'
  belongs_to :clavis_library, foreign_key:'library_id'
  belongs_to :sbct_order_status, foreign_key:'order_status'

  def to_label
    "Item #{self.id} - #{self.sbct_title.titolo} #{self.clavis_library.to_label}"
  end

  def SbctItem.set_clavis_supplier
    self.connection.execute(SbctItem.sql_for_set_clavis_supplier)
  end

  def check_record
    t = self.sbct_title
    # puts "check_record: #{self.id} => #{t.titolo}"

    if !t.nil? and !t.prezzo.blank?
      if self.sbct_supplier.nil?
        self.prezzo = t.prezzo
      else
        sconto = self.sbct_supplier.clavis_supplier.discount.to_i
        self.prezzo = t.prezzo - (sconto * t.prezzo)/100
      end
    end
    self.order_status=nil if self.order_status.blank?
    true
  end

  def SbctItem.sql_for_set_clavis_supplier
    sql = %Q{
with t1 as
(
 SELECT cs.supplier_id,cp.id_copia,cb.budget_year,b.budget_id
  FROM sbct_acquisti.copie cp
   JOIN sbct_acquisti.titoli t USING(id_titolo)
   JOIN clavis.item ci ON(ci.manifestation_id=t.manifestation_id AND ci.home_library_id=cp.library_id)
   JOIN clavis.supplier cs ON(cs.supplier_id=ci.supplier_id)
   JOIN sbct_acquisti.budgets b ON(b.supplier_id = cs.supplier_id)
   JOIN clavis.budget cb ON(cb.budget_id = b.clavis_budget_id)
   WHERE cp.supplier_id IS NULL
      AND ci.inventory_date between cb.start_validity and cb.end_validity
   -- AND date_part('year',ci.inventory_date)=cb.budget_year
)
-- select * from t1;
UPDATE sbct_acquisti.copie c set supplier_id = t1.supplier_id, order_status='A',budget_id=t1.budget_id FROM t1 WHERE t1.id_copia=c.id_copia;
}
    # puts sql
    sql
  end

  def SbctItem.create_order(item_ids_array)
    ids = item_ids_array.map {|c| c.to_i}
    self.connection.execute("UPDATE sbct_acquisti.copie set order_status='O', order_date=now() WHERE id_copia in (#{ids.join(',')});")
  end

  def SbctItem.assegna_prezzo
    sql = %Q{
      update sbct_acquisti.copie c
         set prezzo = t.prezzo - (cs.discount*t.prezzo)/100
      from sbct_acquisti.titoli t, clavis.supplier cs 
       where t.id_titolo = c.id_titolo
          and cs.supplier_id = c.supplier_id
          and c.prezzo is null;
    }
    self.connection.execute(sql)
  end

  def SbctItem.totale_copie
    self.connection.execute("select sum(numcopie) from sbct_acquisti.copie").first['sum'].to_i
  end

  def SbctItem.tutti(sbct_item, params={})
    per_page = params[:per_page].blank? ? 10000 : params[:per_page]
    @sbct_items = SbctItem.paginate_by_sql(SbctItem.sql_for_tutti(sbct_item, params), page:params[:page], per_page:per_page)
  end

  def SbctItem.sql_for_tutti(sbct_item, params={})
    order_by = "order by t.titolo,lc.label"
    attrib=sbct_item.attributes.collect {|a| a if not a.last.blank?}.compact
    cond=[]
    attrib.each do |a|
      name,value=a
      case name
      when 'numcopie'
      when 'order_date'
        cond << "#{name} = '#{value.strftime('%Y-%m-%d')}'"
      # 
      else
        cond << "#{name} = '#{value}'"
      end
    end

    cond << "order_date is null" if params[:order_date]=='NULL'
    
    cond = cond.join(" AND ")
    cond = cond.blank? ? '' : "WHERE #{cond}"

    group_by=params[:group_by].blank? ? '' : "group by #{params[:group_by]}"

    if params[:group_by]=='title'
      @sql = %Q{
SELECT t.titolo,t.id_titolo,t.ean,t.autore,t.editore,array_to_string(array_agg(c.numcopie order by lc.label),','),c.prezzo,sum(c.numcopie) as numcopie,acq.annotazioni,array_to_string(array_agg(lc.label order by lc.label), ', ') as siglebct
      from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo)
           join cr_acquisti.acquisti acq on(acq.id=t.id_titolo) join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
      #{cond}
      group by t.titolo,t.id_titolo,c.prezzo,acq.annotazioni
      order by t.titolo
      }
    else
      @sql = %Q{SELECT t.titolo,t.id_titolo,c.id_copia,c.prezzo as prezzo_scontato,c.numcopie,c.budget_id,c.order_status,c.supplier_id,lc.label as siglabiblioteca
      from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo) join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
      #{cond}
      #{order_by}
      }
    end
    fd=File.open("/home/seb/sbct_orders.sql", "w")
    fd.write(@sql)
    fd.close

    # @sql = %Q{SELECT * from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo) WHERE supplier_id=#{@sbct_supplier.id} #{order_by} }
    @sql
  end

  
  def SbctItem.orders_toc(params)
    self.connection.execute(SbctItem.sql_for_orders_toc(params)).to_a
  end

  def SbctItem.sql_for_orders_toc(params)
    cond = []
    if !params[:order_date].blank?
      if params[:order_date]=='NULL'
        cond << "order_date is null"
      else
        cond << "order_date = #{self.connection.quote(params[:order_date])}"
      end
    end
    if !params[:supplier_id].blank?
      cond << "s.supplier_id = #{self.connection.quote(params[:supplier_id])}"
    end

    cond = cond.join(' and ')
    cond = "AND #{cond}" if !cond.blank?
    sql = %Q{select order_date,supplier_id,s.supplier_name,count(*) as numcopie
      from sbct_acquisti.copie c join sbct_acquisti.suppliers s using(supplier_id) 
       where c.order_status='O' #{cond} group by c.order_date,c.supplier_id,s.supplier_name
          order by c.order_date desc,s.supplier_name;
    }
  end

  
end
