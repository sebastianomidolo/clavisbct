# coding: utf-8
class SbctSupplier < ActiveRecord::Base
  self.table_name='sbct_acquisti.suppliers'
  self.primary_key = 'supplier_id'
  attr_accessible :supplier_name, :supplier_id, :shortlabel, :deposito_legale, :donatore, :tipologie, :esclusivo_per_tipologia, :multibudget, :external_user_id
  attr_accessor :residuo, :budget_esclusivo, :multibudget

  has_many :sbct_items, foreign_key:'supplier_id'
  has_many :sbct_budgets, foreign_key:'supplier_id'
  has_many :sbct_invoices, foreign_key:'supplier_id'
  belongs_to :clavis_supplier, foreign_key:'supplier_id'

  belongs_to :user, foreign_key:'external_user_id'

  has_and_belongs_to_many(:sbct_budgets, join_table:'sbct_acquisti.l_budgets_suppliers',
                          :foreign_key=>'supplier_id',
                          :association_foreign_key=>'budget_id')
  before_save :fix_blanks

  def fix_blanks
    self.tipologie=nil if self.tipologie.blank?
  end

  def clavisbct_username
    "f#{self.id}"
  end

  def to_label
    # "#{self.supplier_name} (id: #{self.id})"
    self.deposito_legale? ? "#{self.supplier_name} (deposito legale)" : self.supplier_name
  end

  # Metodo da riscrivere perché dal 2024 ci troviamo in una situazione per cui lo stesso fornitore
  # che prima faceva un certo sconto poi ne ha fatto un altro e dunque non possiamo legare
  # il fornitore a un solo sconto (lo abbiamo spostato nel budget)
  def discount_do_not_use
    if self.clavis_supplier.nil?
      0.0
    else
      self.clavis_supplier.discount.to_f
    end
  end

  def auto_create_invoices
    budget_label = self.supplier_name.split.first
    sql=%Q{begin;
-- Non serve se non a verificare la situazione prima e dopo la cancellazione delle fatture per questo fornitore:
select invoice_id,count(*) from sbct_acquisti.copie where invoice_id is not null and supplier_id = #{self.id} group by rollup(1);
delete from sbct_acquisti.invoices where supplier_id = #{self.id} and label is null;
with t1 as
(
select cp.supplier_id,cb.library_id,sum(cp.prezzo*cp.numcopie) as speso
  from sbct_acquisti.budgets b join clavis.budget cb on (cb.budget_id=b.clavis_budget_id)
   join sbct_acquisti.copie cp on(cp.budget_id=b.budget_id)
    where b.label ~ '^#{budget_label}' and cp.supplier_id=#{self.id} and cp.invoice_id is null
    and cb.library_id > 1 and cp.order_status IN ('A','O')
      group by cp.supplier_id,cb.library_id
)
insert into sbct_acquisti.invoices(supplier_id,library_id,total_amount) (select supplier_id,library_id,speso from t1);
update sbct_acquisti.copie as c
  set invoice_id=i.invoice_id from sbct_acquisti.invoices i
    where i.supplier_id=c.supplier_id
      and i.library_id=c.library_id
      and c.order_status IN ('A','O') and c.invoice_id is null;
     }
    self.connection.execute(sql)
  end

  def quota_fornitore
    pattern = self.supplier_name[0..4]
    SbctSupplier.quota_fornitore(pattern, pattern)
  end

  def importo_impegnato
    # r = SbctSupplier.tutti({supplier_id:self.id,order_status:["'A'","'O'"]}).first
    r = SbctSupplier.tutti({supplier_id:self.id,order_status:["'A'","'O'"]})
    imp = 0.0
    r.each do |x|
      imp += x.impegnato.to_f
    end
    # r.nil? ? 0 : r.impegnato.to_f
    r.nil? ? 0 : imp
  end

  def importo_residuo
    (self.quota_fornitore - self.importo_impegnato).round(4)
  end

  def libraries
    sql = %Q{
select lc.label,cl.library_id,cl.shortlabel as library_name,sum(numcopie) as numcopie, sum(c.prezzo*c.numcopie) as importo,
   o.label as order_status_label, o.id as order_status
from sbct_acquisti.suppliers s join sbct_acquisti.copie c using(supplier_id)
  join sbct_acquisti.library_codes lc on(lc.clavis_library_id=c.library_id)
  join clavis.library cl on(cl.library_id=c.library_id)
  join sbct_acquisti.order_status o on(o.id = c.order_status)
  where s.supplier_id=#{self.id}
  group by lc.label,cl.library_id,cl.shortlabel,o.label,o.id order by library_name,order_status_label}
    ClavisLibrary.find_by_sql(sql)
  end

  def SbctSupplier.multibudget_select()
    sql = "select multibudget_label,count(*) from sbct_acquisti.pac_suppliers group by multibudget_label having count(*)>1"
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['multibudget_label']} (#{r['count']})"
      res << [label,r['multibudget_label']]
    end
    res
  end

  def SbctSupplier.label_select(params={},user=nil)
    if !params[:supplier_filter].blank?
      v = SbctSupplier.connection.quote_string(params[:supplier_filter])
      filter = "WHERE s.supplier_name ~* '^#{v}'"
    else
      filter = "WHERE not s.supplier_name ~* '^MiC'"
    end

    if !user.nil?
      if SbctTitle.user_roles(user).include?('AcquisitionManager') and params[:supplier_filter].blank?        
        filter = ''
      end
    end
    if filter.blank?
      #filter << "WHERE deposito_legale = false"
    else
      #filter << "AND deposito_legale = false"
    end

    if params[:insert_from_clavis]=='true'
      sql=%Q{select s.supplier_id as key,s.supplier_name as label
         from sbct_acquisti.suppliers s order by s.supplier_name;}

    else
      sql=%Q{select s.supplier_id as key,s.supplier_name as label, s.tipologie
         from sbct_acquisti.suppliers s #{filter} order by s.supplier_name;}
    end
    res = []
    self.connection.execute(sql).to_a.each do |r|
      tp = r['tipologie'].blank? ? '' : " - [#{r['tipologie']}]"
      label = "#{r['label']} #{tp}"
      res << [label,r['key']]
    end
    res
  end

  # Fornitore deposito legale
  def SbctSupplier.dl_select
    sql=%Q{select s.supplier_id as key,s.supplier_name as label
         from sbct_acquisti.suppliers s where deposito_legale order by s.supplier_name;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = r['label']
      res << [label,r['key']]
    end
    res
  end
  
  def SbctSupplier.available_suppliers(pattern_fornitore, pattern_budget, sbct_item)

    quota_fornitore = SbctSupplier.quota_fornitore(pattern_fornitore, pattern_budget)
    puts "massimo per fornitore: #{quota_fornitore}"
    res = []
    # sbct_item.prezzo=40.0
    prm = Hash.new
    prm[:order_status] = ["'A'","'O'"]
    prm[:pattern] = pattern_fornitore
    SbctSupplier.tutti(prm).each do |r|
      i = (quota_fornitore - r.impegnato.to_f)
      # next if i < sbct_item.prezzo
      puts "residuo per #{r.id}: #{i.round(2)}"
      r.costo_medio = i.round(2)
      res << r
    end
    ids = res.collect {|r| r.id}
    sql=%Q{select s.supplier_id,c.library_id,count(*) as numero_copie_fornite from sbct_acquisti.suppliers s left join sbct_acquisti.copie c
           using(supplier_id) where library_id = #{sbct_item.library_id}
         and supplier_id in (#{ids.join(',')}) group by s.supplier_id,c.library_id;}

    h={}
    SbctSupplier.find_by_sql(sql).each do |r|
      puts "r: #{r.numero_copie_fornite} per #{r.supplier_id}"
      h[r.id] = r.numero_copie_fornite.to_i
    end
    puts "h: #{h.inspect}"
    rv = []
    res.each do |r|
      # puts "r: #{r.inspect}"
      r.numero_copie = h[r.id]
      rv << r
    end
    # Occhio: "costo_medio" è un attributo usato qui come alias per "residuo": va inteso come residuo da spendere
    rv.sort { |a, b|  b.costo_medio <=> a.costo_medio }
  end

  # Nuova per il 2023
  def SbctSupplier.available_suppliers_2(sbct_item)
    budget = sbct_item.sbct_budget
    pattern = budget.label.split.first
    a=SbctSupplier.find_by_sql("SELECT * FROM sbct_acquisti.suppliers where supplier_name ~ '^#{pattern}'").collect{|s| s.id}
    return [] if a.size==0

    quota_fornitore = SbctSupplier.quota_fornitore(pattern, pattern)
    puts "massimo per fornitore: #{quota_fornitore}"

    prm = Hash.new
    prm[:order_status] = ["'A'","'O'"]
    prm[:pattern] = pattern
    #prm[:supplier_ids] = budget.sbct_suppliers.collect {|i| i.id}
    prm[:supplier_ids] = a
    puts "here: #{prm[:supplier_ids]}"
    res = []
    SbctSupplier.tutti(prm).each do |r|
      # budget.sbct_suppliers.each do |r|
      i = (quota_fornitore - r.impegnato.to_f)
      # next if i < sbct_item.prezzo
      puts "residuo per #{r.id}: #{i.round(2)}"
      r.costo_medio = i.round(2)
      res << r
    end
    #ids = res.collect {|r| r.id}
    #ids = budget.sbct_suppliers.collect {|i| i.id}
    ids = a
    sql=%Q{select s.supplier_id,c.library_id,count(*) as numero_copie_fornite from sbct_acquisti.suppliers s left join sbct_acquisti.copie c
           using(supplier_id) where library_id = #{sbct_item.library_id}
         and supplier_id in (#{ids.join(',')}) group by s.supplier_id,c.library_id;}
    puts "qui: #{sql}"
    # raise sql
    h={}
    SbctSupplier.find_by_sql(sql).each do |r|
      puts "r: #{r.numero_copie_fornite} per #{r.supplier_id}"
      h[r.id] = r.numero_copie_fornite.to_i
    end
    puts "h: #{h.inspect}"
    rv = []
    res.each do |r|
      # puts "r: #{r.inspect}"
      r.numero_copie = h[r.id]
      rv << r
    end
    # Occhio: "costo_medio" è un attributo usato qui come alias per "residuo": va inteso come residuo da spendere
    rv.sort { |a, b|  b.costo_medio <=> a.costo_medio }
  end

  def SbctSupplier.tutti(params={})
    supplier = SbctSupplier.new(params[:sbct_supplier])
    cond = []
    cond << "s.supplier_name ~* #{self.connection.quote(supplier.multibudget)}" if !supplier.multibudget.blank?
    cond << "s.supplier_name ~* #{self.connection.quote(supplier.supplier_name)}" if !supplier.supplier_name.blank?
    cond << "s.supplier_id in (#{params[:supplier_ids].join(',')})" if !params[:supplier_ids].blank?
    if supplier.deposito_legale?
      cond << "s.deposito_legale"
    else
      # cond << "s.deposito_legale is null"
    end

    if !params[:order_status].blank?
      orderstatus = params[:order_status]
      if orderstatus.class == Array
        cond << "c.order_status IN (#{orderstatus.join(',')})"
      else
        cond << "c.order_status = #{self.connection.quote(orderstatus)}"
      end
    end
    cond << "s.supplier_id=#{self.connection.quote(params[:supplier_id])}" if !params[:supplier_id].blank?
    cond = cond.size==0 ? '' : "WHERE #{cond.join(' AND ')}"
    sql = %Q{
select b.budget_id,b.label as budget_label,s.supplier_name, s.shortlabel, s.supplier_id, s.tipologie,
  b.discount, ps.quota_fornitore, sum(c.numcopie) as numero_copie,
COALESCE((sum(c.prezzo * c.numcopie)),0) as impegnato,
(ps.quota_fornitore - COALESCE((sum(c.prezzo * c.numcopie)),0)) as residuo,
to_char(avg(c.prezzo), 'FM999999999.00') as costo_medio
FROM sbct_acquisti.suppliers s join clavis.supplier cs using(supplier_id)
left join sbct_acquisti.copie c on(c.supplier_id=s.supplier_id and c.order_status in ('O','A'))
left join sbct_acquisti.titoli t using(id_titolo)
left join sbct_acquisti.pac_suppliers ps on(ps.supplier_id=s.supplier_id)
left join sbct_acquisti.budgets b using(budget_id)
#{cond}
group by b.budget_id,b.label,s.supplier_name,s.supplier_id, b.discount,ps.quota_fornitore
order by s.supplier_name,b.label;}
    # puts sql
    fd=File.open("/home/seb/suppliers_tutti.sql", "w")
    fd.write(sql)
    fd.close
    SbctSupplier.find_by_sql(sql)
  end

  def SbctSupplier.quota_fornitore(pattern_fornitore, pattern_budget, difetto=true)
    if difetto==true
      # Arrotondamento per difetto alla seconda cifra decimale
      sql=%Q{select floor((sum(total_amount)/(select count(*) from sbct_acquisti.suppliers
            where supplier_name ~ '^#{pattern_fornitore}'))::numeric(10,4)*100)/100 as "quota_per_fornitore"
       from sbct_acquisti.budgets where label ~ '^#{pattern_budget}';}
    else
      sql=%Q{select (sum(total_amount)/(select count(*) from sbct_acquisti.suppliers
         where supplier_name ~ '^#{pattern_fornitore}'))::numeric(10,2)
             as "quota_per_fornitore" from sbct_acquisti.budgets where label ~ '^#{pattern_budget}';}
    end
    # puts sql
    begin
      self.connection.execute(sql).first['quota_per_fornitore'].to_f
    rescue
      0
    end
  end

  def SbctSupplier.insert_dl_from_clavis
    sql=%Q{INSERT INTO sbct_acquisti.suppliers(deposito_legale,supplier_id,supplier_name) (
         select distinct true,s.supplier_id,s.supplier_name from clavis.supplier s join clavis.item ci using(supplier_id)
           where s.supplier_id is not null and ci.item_source='O')
        on conflict(supplier_id) do nothing;}
    # puts sql
    self.connection.execute(sql)
  end
  def SbctSupplier.insert_from_clavis(supplier_name)
    name = "#{supplier_name.strip}"
    sql=%Q{INSERT INTO sbct_acquisti.suppliers(supplier_id,supplier_name) (
      select cs.supplier_id,cs.supplier_name from clavis.supplier cs
         left join sbct_acquisti.suppliers ps using(supplier_id)
          where cs.supplier_name ~ #{self.connection.quote(name)} and ps is null
       ) on conflict(supplier_id) DO NOTHING;}
    # puts sql                      
    self.connection.execute(sql)      
  end

  def SbctSupplier.suppliers_filter(suppliers_list,qualif)
    res = []
    qualif.split(';').each do |q|
      q.strip!
      # puts "analizzo elemento '#{q}'"
      suppliers_list.each do |s|
        next if s.tipologie.nil?
        s.tipologie.split(';').each do |tp|
          tp.strip!
          if q==tp
            # puts "ok #{s.id} per #{q}"
            res << s
          end
        end
      end
    end
    suppliers_list.each do |s|
      next if !s.tipologie.blank?
      res << s
    end
    res
  end

end
