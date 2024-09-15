# coding: utf-8

class SbctOrder < ActiveRecord::Base
  self.table_name='sbct_acquisti.orders'

  attr_accessible :order_date, :supplier_id, :budget_id, :label, :note, :inviato

  validates :supplier_id, presence: true

  has_many :sbct_items, foreign_key:'order_id'
  belongs_to :sbct_supplier, foreign_key:'supplier_id'
  belongs_to :sbct_budget, foreign_key:'budget_id'

  def to_label
    # "Ordine #{self.id} (#{self.label}) del #{self.order_date.to_date} #{self.sbct_supplier.supplier_name}"
    if self.inviato
      r = "Ordine BCT #{self.id} del #{self.order_date.to_date} #{self.sbct_supplier.supplier_name}"
    else
      r = "Ordine BCT #{self.id} (da inviare) #{self.sbct_supplier.supplier_name}"
    end
    r << " #{self.sbct_budget.to_label}" if !self.sbct_budget.nil?
    # "#{self.label} del #{self.order_date.to_date} #{self.sbct_supplier.supplier_name}"
    r
  end

  def autocreate_list(user)
    sql = %Q{select * from sbct_acquisti.liste where owner_id = #{user.id} and hidden and label='Ordine corrente'}
    lista = SbctList.find_by_sql(sql).first
    return if lista.nil?
    lista.sbct_titles=[]
    sql = %Q{with t1 as (select id_titolo from sbct_acquisti.copie where order_id=#{self.id})
             insert into sbct_acquisti.l_titoli_liste(id_titolo,id_lista)
              (select id_titolo,#{lista.id} from t1) on conflict(id_titolo,id_lista) do nothing;}
    self.connection.execute(sql)
  end

  def discount_check(mode=:list)
    action = 'select distinct * from t1 order by titolo' if mode==:list
    action = 'update sbct_acquisti.copie c set prezzo=t1.prezzo_scontato from t1 where c.id_copia=t1.id_copia' if mode==:update
    sql = %Q{
      with t1 as (
select ti.id_titolo,ti.titolo,ti.prezzo as listino,b.discount,cp.prezzo as prezzo_copia,
   cp.id_copia, round(ti.prezzo-ti.prezzo*(b.discount/100),2) as prezzo_scontato
from sbct_acquisti.copie cp
     join sbct_acquisti.titoli ti using(id_titolo)
     join sbct_acquisti.budgets b on(b.budget_id=cp.budget_id)
where
 order_id=#{self.id} and cp.prezzo != round(ti.prezzo-ti.prezzo*(b.discount/100),2)
)
    #{action}}
  end

  def add_items_to_order(item_ids_array)
    ids = item_ids_array.map {|c| c.to_i}
    sql=%Q{UPDATE sbct_acquisti.copie c SET order_status='O', order_id=o.order_id
          FROM sbct_acquisti.orders o WHERE o.order_id=#{self.id} AND o.inviato = false
           AND c.order_status='S' AND c.order_id IS NULL AND c.supplier_id=o.supplier_id
         AND c.id_copia IN (#{ids.join(',')});
    }
    self.connection.execute(sql)
  end

  def sql_for_order_prepare(with_sql,sbct_title=nil,qb_select=nil)
    fd=File.open("/home/seb/sql_for_order_prepare.sql", "w")
    fd.write("-- generato da sql_for_order_prepare - #{sbct_title.class}\n")
    if sbct_title.clavis_library_ids.nil?
      library_ids = ''
    else
      library_ids = sbct_title.clavis_library_ids.size==0 ? '' : "AND cp.library_id IN(#{sbct_title.clavis_library_ids.join(',')})"
    end

    if !self.budget_id.nil?
      fd.write("-- Ordine su budget #{self.budget_id}\n")
      fd.write("-- sbct_title: #{sbct_title.inspect}\n")
      fd.write("-- sbct_title: #{sbct_title.clavis_library_ids}\n")
      fd.write("-- qb_select: #{qb_select}\n")

      if qb_select.blank?
        qb_select = ''
      else
        qb_select = "AND cp.qb=true" if qb_select=='S'
        qb_select = "AND cp.qb=false" if qb_select=='N'
      end

      sql=%Q{with t as(#{with_sql})
    SELECT t.titolo,cp.numcopie,cp.id_copia,cp.id_titolo,cp.prezzo as prezzo_scontato, cp.budget_id, cp.order_status,cp.supplier_id,
   cp.library_id, cp.supplier_id as fornitore,lc.label as siglabiblioteca,cp.qb
     FROM t
      JOIN sbct_acquisti.copie cp using(id_titolo)
      JOIN sbct_acquisti.budgets b on(b.budget_id=(select budget_id from sbct_acquisti.orders where order_id=#{self.id}))
      JOIN sbct_acquisti.library_codes lc on (lc.clavis_library_id=cp.library_id)
WHERE b.budget_id = cp.budget_id
     and cp.supplier_id = b.supplier_id
     and cp.order_status = 'S' #{library_ids} #{qb_select}
     order by siglabiblioteca,cp.qb,cp.date_updated asc,t.titolo
    }
    else
      fd.write("-- Ordine multibudget (non ha un suo budget specifico)\n")
            sql=%Q{with t as(#{with_sql})
    SELECT t.titolo,cp.numcopie,cp.id_copia,cp.id_titolo,cp.prezzo as prezzo_scontato, cp.budget_id, cp.order_status,cp.supplier_id,
   cp.library_id, cp.supplier_id as fornitore,lc.label as siglabiblioteca,cp.qb
     FROM t
      JOIN sbct_acquisti.copie cp using(id_titolo)
      JOIN sbct_acquisti.library_codes lc on (lc.clavis_library_id=cp.library_id)
WHERE cp.supplier_id = #{self.supplier_id}
     and cp.order_status = 'S' #{library_ids}
     order by siglabiblioteca,cp.qb,cp.date_updated asc,t.titolo
    }

    end
    fd.write(sql)
    fd.close
    sql
  end



  
  # Esempio di utilizzo:
  # SbctOrder.trasforma_copie_selezionate_in_ordini(supplier_name_regexp='^MiC22')
  def SbctOrder.trasforma_copie_selezionate_in_ordini(supplier_name_regexp)
    supplier_ids = SbctSupplier.where("supplier_name ~ '#{supplier_name_regexp}'").collect{|s| s.id}
    puts "supplier_ids: #{supplier_ids}"
    raise "Nessun fornitore corrisponde a #{supplier_name_regexp}" if supplier_ids.size == 0
    sql=%Q{
      UPDATE sbct_acquisti.copie c SET order_status='O', order_id=o.order_id
          FROM sbct_acquisti.orders o WHERE o.inviato = false AND c.supplier_id IN (#{supplier_ids.join(',')})
           AND c.order_status='S' AND c.order_id IS NULL AND c.supplier_id=o.supplier_id;
    }
    puts sql
    self.connection.execute(sql)
  end

  
  def SbctOrder.tutti(params={})
    cond = []
    # cond << "s.supplier_name ~ #{self.connection.quote(params[:pattern])}" if !params[:pattern].blank?
    # cond << "c.order_status = #{self.connection.quote(params[:order_status])}" if !params[:order_status].blank?
    cond << "s.supplier_id=#{self.connection.quote(params[:supplier_id])}" if !params[:supplier_id].blank?
    if params[:all].blank?
      # order_by = 's.supplier_name,o.order_id'
      order_by = 'o.order_id desc'
      if !params[:inviato].blank?
        cond << "o.inviato"
        order_by = 'o.order_id desc'
      else
        cond << "not o.inviato"
        order_by = 'o.order_id'
      end
    else
      # order_by = 'o.order_id desc'
      # order_by = 's.supplier_name,o.order_id'
      order_by = 'o.order_id desc'
    end
    # cond << "c.order_status IN ('O','A')"
    cond = cond.size==0 ? '' : "WHERE #{cond.join(' AND ')}"
    sql=%Q{select o.order_id,o.order_date,s.supplier_id,s.supplier_name,o.label, 
COALESCE(sum(c.numcopie),0) as numero_copie,
COALESCE((sum(c.prezzo * c.numcopie)),0) as totale_ordine, inviato
FROM sbct_acquisti.orders o join sbct_acquisti.suppliers s using(supplier_id) 
left join sbct_acquisti.copie c on(c.order_id=o.order_id and c.order_status IN ('O','A')) left join sbct_acquisti.titoli t using(id_titolo)
#{cond} group by o.order_id,s.supplier_id,o.order_date,o.label
-- order by o.order_date 
order by #{order_by}
    }
    SbctOrder.find_by_sql(sql)
  end

  def SbctOrder.trova_titoli_duplicati
    sql=%Q{with tdup as
(select t.ean from sbct_acquisti.titoli t where t.ean is not null group by t.ean having count(*) > 1)
select cp.id_titolo,t.ean,t.titolo,cp.order_id,array_length(array_agg(cp.id_copia),1) as numcopie
  from sbct_acquisti.copie cp join sbct_acquisti.titoli t using(id_titolo)
   where cp.id_titolo in (select id_titolo from sbct_acquisti.titoli join tdup using(ean))
    and cp.order_id is not null group by 1,2,3,4 order by cp.order_id,t.titolo;}
    SbctTitle.find_by_sql(sql)
  end

  def SbctOrder.azzera_ordini_per_fornitori(suppliers_list)
    puts "Per ordini non inviati, trasformo le copie da 'O' a 'S' e elimino order_id"
    supplier_ids=suppliers_list.collect {|i| i.id}
    
    sql = %Q{
    BEGIN;
     UPDATE sbct_acquisti.copie SET order_id = NULL, order_status='S' WHERE order_id is not null AND supplier_id in (#{supplier_ids.join(',')});
     UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE supplier_id in (#{supplier_ids.join(',')});
    COMMIT;
    }
    self.connection.execute(sql)
  end
end
