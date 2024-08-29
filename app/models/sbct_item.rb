# coding: utf-8
# coding: utf-8
class SbctItem < ActiveRecord::Base
  # self.primary_keys = [:id_titolo, :library_id, :budget_id]
  self.primary_key = 'id_copia'
  self.table_name='sbct_acquisti.copie'

  attr_accessible :id_titolo, :budget_id, :library_id, :numcopie, :order_date, :order_status, :supplier_id, :note_interne, :note_fornitore, :created_by, :home_library_id, :prezzo, :order_id, :supplier_label, :event_id
  # validates :budget_id, presence: true

  attr_accessor :supplier_label, :current_user, :js_code

  before_save :check_record
  after_save :log_changes

  
  belongs_to :sbct_title, foreign_key:'id_titolo'
  belongs_to :sbct_budget, foreign_key:'budget_id',include:'clavis_budget'
  belongs_to :sbct_supplier, foreign_key:'supplier_id'
  belongs_to :sbct_order, foreign_key:'order_id'
  belongs_to :clavis_library, foreign_key:'library_id'
  belongs_to :clavis_home_library, class_name:'ClavisLibrary', foreign_key:'home_library_id'
  belongs_to :sbct_order_status, foreign_key:'order_status'
  belongs_to :sbct_event, foreign_key:'event_id'

  def to_label
    "Item #{self.id} - #{self.sbct_title.titolo} #{self.clavis_library.to_label}"
  end

  def log_changes
    return if !self.changed?
    if self.current_user.nil?
      self.current_user=User.find(216)
    end
    data = self.changes.to_json
    sql = %Q{INSERT INTO sbct_acquisti.changes (object_class, object_id, updated_by, data)
                    VALUES('#{self.class}', #{self.id}, #{self.current_user.id}, #{self.connection.quote(data)});}
    self.connection.execute(sql)
  end

  def set_clavis_item_ids
    SbctItem.set_clavis_item_ids(self.id_titolo)
  end

  def prezzo_con_sconto_applicato
    pt=self.sbct_title.prezzo
    return nil if pt.nil?
    #return pt if self.supplier_id.nil?
    #sconto = self.sbct_supplier.clavis_supplier.discount.to_f
    return pt if self.budget_id.nil?
    sconto = self.sbct_budget.discount.to_f
    return pt if sconto.nil?
    (pt - (pt * sconto)/100).round(2)
  end

  def editable?(user)
    if (user.role?('AcquisitionStaffMember') or user.role?('AcquisitionManager')) \
      or (user.role?('AcquisitionLibrarian') and self.created_by == user.id) \
      or (user.role?('AcquisitionLibrarian') and user.clavis_libraries_ids.include?(self.library_id))
      true
    else
      false
    end
  end
  
  def assign_to_other_supplier(target_supplier)
    puts "Assegno la copia con id #{self.id} al fornitore #{target_supplier.id}"
    # Verifico se questa copia è già su un ordine o meno
    if self.order_id.nil?
      self.supplier_id=target_supplier.id      
    else
      puts "ordine attuale: #{self.order_id}"
      puts self.inspect
      self.supplier_id=target_supplier.id
      puts "trovo l'ordine a cui associare la copia con il nuovo fornitore #{self.supplier_id}"
      order_id = self.connection.execute("select order_id from #{SbctOrder.table_name} where supplier_id=#{self.supplier_id} and not inviato order by order_id limit 1").first
      raise "Il fornitore #{self.supplier_id} non dispone di un ordine non ancora inviato al quale poter associare la copia #{self.id}" if order_id.nil?
      self.order_id = order_id['order_id'].to_i
      self.order_status='O' if self.order_status == 'S'
      puts "order_id: #{order_id} - order_status: #{self.order_status}"
      puts self.inspect
    end
    self.save if self.changed?
  end

  def save_before_delete(user_id)
    data = self.attributes
    data.delete_if{|k,v| v.blank?}
    data = data.to_json
    sql = %Q{INSERT INTO sbct_acquisti.deleted (object_class, object_id, deleted_by, data)
                    VALUES('#{self.class}', #{self.id}, #{user_id}, #{self.connection.quote(data)});}
    self.connection.execute(sql)
  end

  def batch_insert_sql(title_ids,user)
    budget_id = self.budget_id.nil? ? 'NULL' : self.budget_id
    if user.role?('AcquisitionLibrarian')
      strongness=1
      qb=true
    else
      strongness='NULL'
      qb=false
    end
    sql_template = %Q{select t.id_titolo,'S' as order_status,#{self.library_id} as library_id,
      #{user.id} as created_by,
      b.budget_id as budget_id, s.supplier_id as supplier_id,
      CASE WHEN s is null THEN t.prezzo
      ELSE
       round(t.prezzo-t.prezzo*(b.discount/100),2)
      END as prezzo,
      #{qb} as qb, #{strongness} as strongness
        from sbct_acquisti.titoli t left join sbct_acquisti.copie cp
   on(cp.id_titolo = t.id_titolo and cp.library_id=#{self.library_id})

       __budgetjoin__

       left join sbct_acquisti.suppliers s on(s.supplier_id=b.supplier_id)
      where cp is null 
       __conditions__
      and t.id_titolo in (#{title_ids.join(',')})}

    sql = ''
    if budget_id==0
      sq1 = sql_template.sub("__conditions__", "and b.locked is false and b.current is true and b.supplier_id is not null")
      sq2 = sq1
      sq1 = sq1.sub("__budgetjoin__", "join sbct_acquisti.budgets b on ( b.reparto=t.reparto )")
      sq2 = sq2.sub("__budgetjoin__", "join sbct_acquisti.budgets b on ( b.reparto is null )")
      sql = %Q{INSERT INTO sbct_acquisti.copie (id_titolo,order_status,library_id,created_by,budget_id,supplier_id,prezzo,qb,strongness)
         (#{sq1});
INSERT INTO sbct_acquisti.copie (id_titolo,order_status,library_id,created_by,budget_id,supplier_id,prezzo,qb,strongness)
         (#{sq2});
      }
    else
      sq1 = sql_template.sub("__conditions__", "")
      sq1 = sq1.sub("__budgetjoin__", "join sbct_acquisti.budgets b on (b.budget_id=#{budget_id})")
      sql = %Q{INSERT INTO sbct_acquisti.copie (id_titolo,order_status,library_id,created_by,budget_id,supplier_id,prezzo,qb,strongness)
         (#{sq1});
      }
    end
    %Q{BEGIN;
     #{sql}
COMMIT;
    }
  end

  def togli_da_ordine
    order = self.sbct_order
    if order.nil?
      puts "Questo item non ho order_id, non faccio niente"
      return
    else
      if order.inviato?
        puts "ordine #{order_id} è già stato inviato, non faccio nulla!"
      else
        # sql = %Q{update sbct_acquisti.copie set order_id = NULL, supplier_id=NULL, order_status='S' where id_copia = #{self.id};}
        sql = %Q{update sbct_acquisti.copie set order_id = NULL, order_status='S' where id_copia = #{self.id};}
        puts sql
        self.connection.execute(sql)
      end
    end
  end

  def aggiungi_a_ordine(new_order)
    if !self.sbct_order.nil?
      raise "copia #{self.id} ha già ordine #{self.sbct_order.id}"
    end
    sql = %Q{update sbct_acquisti.copie set order_id = #{new_order.id}, order_status='O' where id_copia = #{self.id};}
    self.connection.execute(sql)
  end

  def supplier_unassign
    sql = %Q{update sbct_acquisti.copie set supplier_id = NULL where id_copia = #{self.id} and order_status='S' and supplier_id is not null;}
    self.connection.execute(sql)
  end

  # Esempio: SbctItem.multi_items_insert({"id_titolo"=>"411189", "budget_id"=>"2", "library_id"=>["", "4", "15", "16"], "user_id"=>9})
  def SbctItem.multi_items_insert(params)
    # puts params.inspect
    proc = 'SbctItem.multi_items_insert'
    raise "#{proc}: parametro library_id obbligatorio" if params['library_id'].blank?
    library_ids = params['library_id'].reject { |c| c.empty? }.uniq
    puts library_ids.join(',')

    id_titolo = params['id_titolo']
    raise "#{proc}: parametro id_titolo non presente" if id_titolo.blank?
    raise "#{proc}: id_titolo #{id_titolo} non trovato" if !SbctTitle.exists?(id_titolo)

    user_id = params['user_id']
    raise "#{proc}: parametro user_id non presente" if user_id.blank?
    raise "#{proc}: User #{user_id} non trovato" if !User.exists?(user_id)
    user = User.find(user_id)
    roles = SbctTitle.user_roles(user)
    # if !['AcquisitionManager','AcquisitionStaffMember','AcquisitionLibrarian'].include?(roles.join)
    if !user.role?(['AcquisitionManager','AcquisitionStaffMember','AcquisitionLibrarian'])
      #if user.email=='stemar'
      #  raise "sei stemar con #{roles.inspect}"
      #end
      raise "#{proc}: user #{user.id} non può inserire copie in sbct_items"
    end

    note_interne = nil
    budget_id = supplier_id = nil
    if !params[:budget_id].blank?
      if params[:budget_id].to_i > 0
        budget = SbctBudget.find(params['budget_id'])
        supplier = budget.sbct_supplier
        raise "#{proc}: per il budget #{budget.id} non c'è un fornitore associato" if supplier.nil?
        order_status = budget.clavis_budget_id.nil? ? 'A' : 'S'
        budget_id = budget.id
        supplier_id = supplier.id
      end
    else
      order_status = 'S'
      supplier_id=params['supplier_id']
      if SbctSupplier.exists?(supplier_id)
        if SbctSupplier.find(supplier_id).deposito_legale?
          order_status = 'A'
          note_interne = 'Deposito legale'
          @no_budget = true
        end
      end
    end
    # Da fare: controllare se lo user corrente può agire sulla biblioteca (ancora da fare!)
    library_ids.each do |library_id|
      if params[:budget_id].to_i == 0 and @no_budget.nil?
        budget_id = nil
        order_status = 'S'
        bdg = self.connection.execute("select budget_id from sbct_acquisti.l_budgets_libraries bl join sbct_acquisti.budgets b using(budget_id) where clavis_library_id=#{library_id} and locked is false and supplier_id is null limit 1").first
        budget_id = bdg['budget_id'].to_i if !bdg.nil?
        # raise "cerco budget per #{library_id} - #{bdg}"
      end
      i = SbctItem.new(budget_id:budget_id,library_id:library_id,supplier_id:supplier_id,id_titolo:id_titolo,created_by:user.id,order_status:order_status,note_interne:note_interne)
      # raise "i: #{i.attributes}"

      if user.role?('AcquisitionLibrarian') and user.clavis_libraries.collect {|l| l.library_id if l.library_id==i.library_id}.compact.size > 0
        i.strongness=1
        i.qb=true
      else
        i.qb=false
      end
      i.save!
    end
    nil
  end

  def SbctItem.auto_insert(with_sql,sbct_item,parms={})
    library_filter=" and cp.library_id=#{sbct_item.library_id}"
    sql = %Q{with t1 as (#{with_sql})\n
      select t1.id_titolo,t1.isbn, t1.manifestation_id,t1.collana,t1.datapubblicazione,NULL as data_ins_in_lista,
       t1.anno,t1.reparto,t1.date_created,t1.prezzo,t1.target_lettura,t1.titolo,t1.infocopie,t1.note,
       t1.editore,t1.autore,
       cp.id_copia,cp.library_id from t1 left join sbct_acquisti.copie cp
           on(cp.id_titolo = t1.id_titolo#{library_filter}) where cp is null;
             }
    fd = File.open("/home/seb/sql_for_autoseleziona_copie.sql", 'w')
    fd.write(sql)
    fd.close
    sql
  end

  def SbctItem.sql_for_budget_assign(with_sql,sbct_item,parms={})
    sql = %Q{with t1 as (#{with_sql})\n
      select t1.id_titolo,t1.isbn, t1.manifestation_id,t1.collana,t1.datapubblicazione,NULL as data_ins_in_lista,
       t1.anno,t1.reparto,t1.date_created,t1.prezzo,t1.target_lettura,t1.titolo,t1.infocopie,
       t1.editore,t1.autore,
       cp.id_copia,cp.library_id from t1 left join sbct_acquisti.copie cp
           on(cp.id_titolo = t1.id_titolo) where cp.order_status='S';
             }
    fd = File.open("/home/seb/sql_for_budget_assign.sql", 'w')
    fd.write(sql)
    fd.close
    sql
  end

  
  def SbctItem.set_clavis_supplier
    self.connection.execute(SbctItem.sql_for_set_clavis_supplier)
  end

  def check_record
    t = self.sbct_title
    # raise "check_record: #{self.id} => #{t.titolo} - prezzo del titolo: #{t.prezzo}"

    if !self.budget_id.nil? and self.supplier_id.nil? and self.order_status=='S'
      (
        b = self.sbct_budget
        s = b.sbct_supplier
        if !s.nil?
          self.supplier_id=s.id
        end
      )
    end
    
    if !t.nil? and !t.prezzo.blank?
      if self.sbct_supplier.nil?
        self.prezzo = t.prezzo
      else
        if self.order_status=='S'
          self.prezzo = self.prezzo_con_sconto_applicato
        else
          self.prezzo = t.prezzo if self.prezzo.nil?
        end
      end
    end

    self.order_status=nil if self.order_status.blank?
    self.note_interne=nil if self.note_interne.blank?
    self.note_fornitore=nil if self.note_fornitore.blank?

    if self.id.nil?
      self.date_created = Time.now
    else
      self.date_updated = Time.now
      self.set_clavis_item_ids
    end
    true
  end

  def SbctItem.items_per_libraries(params={})
    sql = self.sql_for_items_per_libraries(params)
    SbctItem.find_by_sql(sql)
  end
  
  def SbctItem.sql_for_items_per_libraries(params={})
    if params.class == Hash
      # puts "params #{params.inspect}"
      cond = []
      cond << "order_id=#{params[:order_id].to_i}" if !params[:order_id].nil?
      cond << "pbud.budget_id IN (#{params[:budget_ids]})" if !params[:budget_ids].nil?

      cond << "cp.supplier_id=#{params[:supplier_id].to_i}" if !params[:supplier_id].nil?
      cond << "budget_id in (select budget_id from sbct_acquisti.budgets where label ~ #{SbctItem.connection.quote(params[:budget_label])})" if !params[:budget_label].blank?
      cond << "order_status=#{SbctItem.connection.quote(params[:order_status])}" if !params[:order_status].nil?
      cond << "cp.order_status IN ('A','O')" if !params[:arrivati_o_ordinati].nil?
      cond << "cp.library_id IN (#{params[:library_ids].join(',')})" if !params[:library_ids].nil?
      cond << "cp.prezzo is null" if params[:prezzo_copia]=='isnull'
      cond << "cp.numcopie > 1 " if params[:numcopie]=='m'
      cond << "cp.qb is true and cp.order_status in ('O','A','S')" if !params[:qb].blank?
      join_liste = ''
      if !params[:id_lista].nil?
        # cond << "tl.id_lista=#{params[:id_lista].to_i}"
        cond << "tl.id_lista IN (select id_lista from sbct_acquisti.liste where parent_id=#{params[:id_lista].to_i} or id_lista=#{params[:id_lista].to_i})"
        join_liste = "JOIN sbct_acquisti.l_titoli_liste tl using(id_titolo)"
      end
      if cond.size==0
        cond = ''
      else
        cond = "WHERE #{cond.join(' AND ')}"
      end

      sql = %Q{
-- Nuova febbraio 2023 - aggiornamento 6 giugno 2023 e 26 febbraio 2024
with t1 as
  (select pbud.budget_id,pbud.total_amount as budget_amount,lc.label as siglabct,cl.library_id,
  --  substr(cl.description,6) as biblioteca,
  description as biblioteca,
  sum(cp.prezzo*cp.numcopie) as importo_speso,
--case when cp.qb is null then 0 else  sum(cp.prezzo*cp.numcopie) end as importo_speso_quota,
      sum(cp.numcopie) as numero_copie,
      pbud.partial_amount as importo_spendibile,
      pbud.subquota_amount as importo_spendibile_quota,
      pbud.quota, pbud.quota_percent, pbud.subquota, qb
      from sbct_acquisti.library_codes lc join clavis.library cl on(cl.library_id=lc.clavis_library_id and lc.pac is true)
    join sbct_acquisti.copie cp using(library_id)
   left join public.pac_budgets pbud on(pbud.budget_id=cp.budget_id and pbud.library_id=cp.library_id)
     #{join_liste}

     -- inizio condizioni:
     #{cond}
     -- fine condizioni
     group by qb,pbud.quota_percent,pbud.budget_id,pbud.total_amount,lc.label,cl.library_id,pbud.partial_amount,pbud.subquota_amount,pbud.quota,pbud.subquota
  ) select
--  budget_id,budget_amount,
    qb,siglabct,
    quota,
    case when qb is true then subquota else quota_percent end as subquota,
    case when qb is true then importo_spendibile_quota else importo_spendibile-importo_spendibile_quota end as assegnati,
    importo_speso as spesi,
    case when qb is true then
       importo_spendibile_quota - importo_speso
    else
       importo_spendibile - importo_spendibile_quota - importo_speso
    end as ancora_disp,
   library_id,
   importo_spendibile as totale_assegnato,
   biblioteca,


    case when qb is true then
     case when importo_spendibile_quota > 0 then
      round((100 * importo_speso / importo_spendibile_quota ),2)
     else
      NULL
     end
    else
     case when importo_spendibile > 0 then
      round((100 * importo_speso / importo_spendibile ),2)
     else
      NULL
     end
    end as spesi_percent,
    numero_copie,
    round((importo_speso / numero_copie),2) as prezzo_medio
   
     from t1
    order by budget_id,siglabct,qb nulls first;}

    else
      with_sql=params.sub('sbct_acquisti.copie', 'sbct_acquisti.copie')
      # with_sql=params.sub('sbct_acquisti.copie', 'public.pac_items')
      # puts "with_sql: #{with_sql}"

      sql = %Q{
        with t1 as (#{with_sql})
select lc.label as siglabct,cl.library_id,substr(cl.description,6) as biblioteca,sum(cp.prezzo*cp.numcopie) as importo,
    count(*) as numero_copie,
    round((100 * sum(cp.prezzo*cp.numcopie) / (sum(sum(cp.prezzo*cp.numcopie)) OVER ())),2) as percentuale
 from t1 join public.pac_items cp using(id_titolo)
    join sbct_acquisti.library_codes lc on (lc.clavis_library_id=cp.library_id and lc.pac is true)
    join clavis.library cl on(cl.library_id=lc.clavis_library_id)
     group by lc.label,cl.library_id
     order by percentuale desc
    }      
    end

    #if params.class==String or !params[:dbg].nil?
      fd = File.open("/home/seb/sql_for_items_per_libraries.sql", "w")
      fd.write(sql)
      fd.close
    #end
    sql
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

  def SbctItem.assegna_prezzo
    sql = %Q{
      update sbct_acquisti.copie c set prezzo = t.prezzo - (b.discount*t.prezzo)/100
        from sbct_acquisti.titoli t, sbct_acquisti.budgets b 
       where t.prezzo is not null and t.prezzo > 0 and t.id_titolo = c.id_titolo
          and b.budget_id = c.budget_id and c.prezzo is null;
    }
    self.connection.execute(sql)
  end

  def SbctItem.totale_copie
    self.connection.execute("select sum(numcopie) from sbct_acquisti.copie").first['sum'].to_i
  end

  def SbctItem.somma_prezzo(items)
    res=0.0
    # items.collect {|r| next if r.order_status=='N'; res += (r.prezzo_scontato.to_f * r.numcopie) }
    items.collect {|r| res += (r.prezzo_scontato.to_f * r.numcopie) }
    res
  end

  def SbctItem.order_items(sbct_order,params={})
    SbctItem.find_by_sql(SbctItem.sql_for_order_items(sbct_order,params))
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
      when 'order_status'
        value = 'O' if value=='OP'
        cond << "order_status='#{value}'"
      when 'numcopie'
      when 'order_date'
        cond << "#{name} = '#{value.strftime('%Y-%m-%d')}'"
      # 
      else
        cond << "c.#{name} = '#{value}'"
      end
    end

    # cond << "order_date is null" if params[:order_date]=='NULL'
    cond << "c.created_by=#{self.connection.quote(params[:created_by].to_i)}" if !params[:created_by].blank?
    cond << "c.updated_by=#{self.connection.quote(params[:updated_by].to_i)}" if !params[:updated_by].blank?
    cond << "c.qb = 't'" if params[:qb]=='t'
    join_vcopie=''
    if !params[:item_status].blank?
      join_vcopie='JOIN sbct_acquisti.vcopie vc using(id_copia)'
      if params[:item_status]=='NP'
        cond << "vc.item_status IS NULL"
      else
        cond << "vc.item_status=#{self.connection.quote(params[:item_status])}"
      end
    end
    if !params[:item_source].blank?
      join_vcopie='JOIN sbct_acquisti.vcopie vc using(id_copia)' if join_vcopie.blank?
      cond << "vc.item_source=#{self.connection.quote(params[:item_source])}"
    end

    join_order=''
    if sbct_item.order_status=='OP'
      # Ordine in preparazione (non ancora inviato)
      join_order="JOIN sbct_acquisti.orders o using (order_id)"
      cond << "not o.inviato"
    end
    
    if sbct_item.supplier_label.blank?
      join_suppliers = ''
    else
      join_suppliers = "JOIN sbct_acquisti.suppliers suppl ON(suppl.supplier_id=c.supplier_id)"
      cond << "suppl.supplier_name ~* #{self.connection.quote(sbct_item.supplier_label)}"
    end

    cond = cond.join(" AND ")
    if cond.blank?
      cond = "WHERE c.id_copia < 1"
      order_by = "order by random()"
    else
      cond = "WHERE #{cond}"
      order_by = "order by t.titolo,lc.label"
    end

    group_by=params[:group_by].blank? ? '' : "group by #{params[:group_by]}"

    if params[:group_by]=='title'
      @sql = %Q{
SELECT t.titolo,t.id_titolo,t.ean,t.autore,t.editore,array_to_string(array_agg(c.numcopie order by lc.label),','),c.prezzo as prezzo_scontato,sum(c.numcopie) as numcopie,acq.annotazioni,array_to_string(array_agg(lc.label order by lc.label), ', ') as siglebct
      from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo)
           join cr_acquisti.acquisti acq on(acq.id=t.id_titolo) join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
      -- join_order
      #{join_order}
      #{cond}
      group by t.titolo,t.id_titolo,c.prezzo,acq.annotazioni
      order by t.titolo
      }
    else
      @sql = %Q{SELECT t.titolo,t.id_titolo,c.id_copia,c.prezzo as prezzo_scontato,c.numcopie,c.budget_id,c.order_status,c.supplier_id,lc.label
    as siglabiblioteca, lc2.label as destlibrary
   from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo)
      join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
      left join sbct_acquisti.library_codes lc2 on (lc2.clavis_library_id=c.home_library_id)
      #{join_vcopie}
      #{join_suppliers}
      -- join_order
      #{join_order}
      #{cond}
      #{order_by}
      }

    end
    fd=File.open("/home/seb/sbct_items_search.sql", "w")
    fd.write(@sql)
    fd.close
    @sql
  end

  def SbctItem.created_by_select
    sql=%Q{select u.id as key, u.email as label from sbct_acquisti.copie c join public.users u on(u.id = c.created_by)
        where c.created_by is not null
        group by u.id,u.email order by u.email;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']}"
      res << [label,r['key']]
    end
    res
  end

  def SbctItem.updated_by_select
    sql=%Q{select u.id as key, u.email as label from sbct_acquisti.copie c join public.users u on(u.id = c.updated_by)
        where c.updated_by is not null
        group by u.id,u.email order by u.email;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']}"
      res << [label,r['key']]
    end
    res
  end

  def SbctItem.sql_for_gest_data(clavis_manifestation_id,supplier_id=nil)
    cond = supplier_id.nil? ? '' : "and cs.supplier_id=#{supplier_id.to_i}"
    tit = SbctTitle.find_by_manifestation_id(clavis_manifestation_id)
    collocazione = tit.nil? ? '' : tit.collocazione_decentrata
    sql=%Q{
SELECT distinct #{self.connection.quote(collocazione)} as colldec,t.manifestation_id,t.id_titolo,cp.supplier_id,cs.supplier_name,
 replace(t.prezzo::varchar,'.',',') as valore_inventariale,
 replace(cs.discount::varchar,'.',',') as sconto,
 replace(cp.prezzo::varchar,'.',',') as importo,



case when (s.deposito_legale is null or not s.deposito_legale) and (s.donatore is null or not s.donatore) then
   'C' -- Acquisto diretto
else
   case when s.deposito_legale then
     'O'
   else
      case when cs.vat_code is null then 'E' else 'F' end
   end
end as item_source,

array_to_string(array_agg(lc.label order by lc.label), ',') as siglebct,
 array_to_string(array_agg(cp.library_id order by library_id), ',') as library_ids
  FROM sbct_acquisti.vcopie cp
 join sbct_acquisti.library_codes lc on (lc.clavis_library_id=cp.library_id)
 join sbct_acquisti.titoli t using(id_titolo)
 join sbct_acquisti.suppliers s using(supplier_id)
 join clavis.supplier cs on (cs.supplier_id=s.supplier_id)
 where t.manifestation_id=#{clavis_manifestation_id.to_i} AND cp.clavis_item_id is null and cp.status IN('A','O') #{cond}
 group by 1,2,3,4,5,6,7,8,9}
    fd=File.open("/home/seb/sql_for_gest.sql", "w")
    fd.write("#{sql};\n")
    fd.close
    sql
  end

  def SbctItem.sql_for_order_items(sbct_order,params)
    order_by = "t.titolo"
    order_by = "c.order_status,t.titolo,lc.label" if params[:order_by]=='order_status'
    order_by = "lc.label,t.titolo" if params[:order_by]=='library'
    order_by = "categoria,t.titolo" if params[:order_by]=='bigliettini_multicopia_split'
    order_by = "t.titolo" if params[:order_by]=='bigliettini'
    group_by=params[:group_by].blank? ? '' : "group by #{params[:group_by]}"

    cond = []
    cond << "c.order_id=#{sbct_order.id}" if !sbct_order.id.nil?
    cond << "c.data_arrivo=#{self.connection.quote(params[:data_arrivo])}" if !params[:data_arrivo].blank?
    cond << "c.order_status=#{self.connection.quote(params[:order_status])}" if !params[:order_status].blank?
    cond << "c.invoice_id=#{self.connection.quote(params[:invoice_id])}" if !params[:invoice_id].blank?

    cond << "c.id_titolo=#{self.connection.quote(params[:id_titolo])}" if !params[:id_titolo].blank?

    cond << "c.order_status IN ('A','O')" if !params[:arrivati_o_ordinati].nil?

    if !params[:id_copia].nil?
      ids = params[:id_copia]
      ids = ids.split.join(",")
      cond << "c.id_copia IN (#{ids})"
    end
    if !params[:dnoteid].blank?
      delivery_date,delivery_note = params[:dnoteid].split('|')
      cond << "rl.numerobollaconsegna=#{delivery_note.to_i}"
      cond << "rl.datainviomerce=#{self.connection.quote(delivery_date)}"
    end
    cond << "c.supplier_id=#{self.connection.quote(params[:supplier_id])}" if !params[:supplier_id].blank?
    # cond << "(c.note_fornitore is not null or c.note_interne ~* 'lettore')" if params[:note_fornitore]=='notnull'
    cond << "(c.note_fornitore is not null or c.note_interne is not null)" if params[:note_fornitore]=='notnull'
    cond = cond.join(' AND ')
    cond = "WHERE #{cond}" if !cond.blank?
    if params[:group_by]=='title'
      @sql = %Q{
SELECT t.titolo,t.id_titolo,t.ean,t.autore,t.editore,t.prezzo as listino,array_to_string(array_agg(c.numcopie order by lc.label),','),c.prezzo as prezzo_scontato,rl.numerobollaconsegna,
    sum(c.numcopie) as numcopie,array_to_string(array_agg(lc.label order by lc.label), ', ') as siglebct,
    array_to_string(array_agg(lc2.label order by lc2.label), ', ') as siglebctdest,
    array_to_string(array_agg(c.note_fornitore order by c.note_fornitore), ', ') as note_fornitore,
    array_to_string(array_agg(c.note_interne), ', ') as note_interne,
     s.supplier_id,s.supplier_name,s.shortlabel,c.data_arrivo,c.order_id,
     case when sum(c.numcopie) = 1 then 'S' else 'M' end as categoria
      from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo)
           join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
           left join sbct_acquisti.library_codes lc2 on (lc2.clavis_library_id=c.home_library_id)	
           join sbct_acquisti.suppliers s on(s.supplier_id=c.supplier_id)
           left join sbct_acquisti.report_logistico rl using(id_titolo)
      #{cond}
      group by t.titolo,t.id_titolo,c.prezzo,s.supplier_id,c.data_arrivo,c.order_id,rl.numerobollaconsegna
      order by #{order_by}
      }
      @sql = %Q{
SELECT t.titolo,t.id_titolo,t.ean,t.autore,t.editore,t.prezzo as listino,array_to_string(array_agg(c.numcopie order by lc.label),','),c.prezzo as prezzo_scontato,
-- rl.numerobollaconsegna,
    sum(c.numcopie) as numcopie,array_to_string(array_agg(lc.label order by lc.label), ', ') as siglebct,
    array_to_string(array_agg(lc2.label order by lc2.label), ', ') as siglebctdest,
    array_to_string(array_agg(c.note_fornitore order by c.note_fornitore), ', ') as note_fornitore,
    array_to_string(array_agg(c.note_interne), ', ') as note_interne,
     s.supplier_id,s.supplier_name,s.shortlabel,c.data_arrivo,c.order_id,
     case when sum(c.numcopie) = 1 then 'S' else 'M' end as categoria
      from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo)
           join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
           left join sbct_acquisti.library_codes lc2 on (lc2.clavis_library_id=c.home_library_id)	
           join sbct_acquisti.suppliers s on(s.supplier_id=c.supplier_id)
  --          left join sbct_acquisti.report_logistico rl using(id_titolo)
      #{cond}
      group by t.titolo,t.id_titolo,c.prezzo,s.supplier_id,c.data_arrivo,c.order_id
-- ,rl.numerobollaconsegna
      order by #{order_by}
      }

    else
      @sql = %Q{SELECT t.titolo,t.id_titolo,c.id_copia,c.prezzo as prezzo_scontato,c.numcopie,c.budget_id,c.order_status,
              c.supplier_id,c.data_arrivo,lc.label as siglabiblioteca,
	      age(c.data_arrivo,ord.order_date) as order_age,
	      case when age(c.data_arrivo,ord.order_date) > interval '60 days' then true else false end as in_ritardo
      from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo)
       join sbct_acquisti.orders ord using(order_id)
       join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
      #{cond}
      order by #{order_by}
      }
    end
    fd=File.open("/home/seb/sql_for_order_items.sql", "w")
    fd.write(@sql)
    fd.close
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

  def SbctItem.rearrange_items(items_array)
    a=items_array
    puts a.inspect
    passi = (a.size / 6) + 10
    # avanzo = a.size - (a.size % 6)
    if (a.size % 6) > 0
      avanzo=a.pop(a.size % 6)
    else
      avanzo = []
    end

    puts "#{a.size} elementi / #{passi} passi - avanzo: #{avanzo.inspect}"

    h={}
    res=[]
    cnt = 0
    (0..passi).each do |i|
      (1..a.size).step(6).each do |f|
        break if a[cnt].nil?
        puts "#{a[cnt]} in posizione #{f+i} (f=#{f} / i=#{i})"
        h[f+i]=a[cnt]
        # res << a[cnt]
        cnt += 1
      end
      break if cnt > a.size
    end
    puts "res.size: #{res.size}"
    res = h.sort.collect{|e| e.last}
    res.concat(avanzo)
  end

  def SbctItem.create_order_file(supplier,items,format,budget)
    require 'csv'
    # budget.nil? qui significa che questo ordine è per un fornitore tipo MiC (non ha un singolo budget associato, ma multipli budget)
    if budget.nil?
      csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
        csv << ['CodiceEan','Autore','Titolo','Editore','Copie','Prezzo','Totale','Biblioteche','Note']
        items.each do |r|
          note = r.note_fornitore; note = '-' if note.blank?
          csv << [r.ean,r.autore,r.titolo,r.editore,r.numcopie,r.prezzo_scontato,sprintf('%.02f', (r.prezzo_scontato.to_f*r.numcopie)),r.siglebct,note]
        end
      end
    else
      cnt = 0
      csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
        csv << ['CodiceEan','Autore','Titolo','Editore','Quantità','Valore unitario','Sconto','Netto','RifOrdine','ProgOrdine','Note','Altre note']
        items.each do |r|
          cnt += 1
          prog_ordine="#{cnt} id #{r.id_titolo}"
          note = r.note_fornitore; note = '-' if note.blank?
          csv << [r.ean,r.autore,r.titolo,r.editore,r.numcopie,r.listino,budget.discount,sprintf('%.02f', (r.prezzo_scontato.to_f*r.numcopie)),r.order_id,prog_ordine,r.siglebct,note]
        end
      end
    end
    if format==:csv
      return csv_string
    else
      # Andrebbero usati veri nomi temporanei e non questi:
      csvfile="/home/seb/tempfile.csv"
      xlsfile="/home/seb/prova.xls"
      File.delete(xlsfile) if File.exists?(xlsfile)
      fd = File.open(csvfile, "w")
      fd.write(csv_string)
      fd.close
      require 'open3'
      cmd = %Q{LANG='en_US.UTF-8' Rscript --vanilla /home/ror/clavisbct/extras/R/write_excel.r "#{csvfile}"}
      @stdout,@stderr,@status=Open3.capture3(cmd)
      return File.read(xlsfile)
    end
  end

  def SbctItem.set_clavis_item_ids(id_titolo=nil)
    cond = id_titolo.nil? ? '' : "t.id_titolo=#{id_titolo} AND"
    sql=%Q{with t1 as (
         select c.id_copia,ci.item_id from sbct_acquisti.copie c join sbct_acquisti.titoli t using(id_titolo)
          join clavis.item ci on (ci.manifestation_id=t.manifestation_id
                  and ci.home_library_id=c.library_id and ci.supplier_id = c.supplier_id)
         where #{cond} c.clavis_item_id is null and ci.manifestation_id > 0)
         update sbct_acquisti.copie c set clavis_item_id=t1.item_id from t1 where t1.id_copia=c.id_copia;
    }
    # puts sql
    self.connection.execute(sql)
    nil
  end
end
