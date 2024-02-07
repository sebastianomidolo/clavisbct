# coding: utf-8
class SbctBudget < ActiveRecord::Base

  self.table_name='sbct_acquisti.budgets'
  attr_accessible :clavis_budget_id, :supplier_id, :locked, :label, :total_amount, :reparto, :current, :sbct_supplier_ids, :supplier_filter, :auto_assign_suppliers
  attr_accessor :supplier_filter, :residuo, :num_fornitori_preassegnati
  belongs_to :clavis_budget
  after_save :insert_l_budget_library


#  has_and_belongs_to_many(:clavis_libraries, join_table:'sbct_acquisti.l_budgets_libraries',
#                          :foreign_key=>'budget_id',
#                          :association_foreign_key=>'clavis_library_id')

  has_and_belongs_to_many(:sbct_l_budget_libraries,join_table:'sbct_acquisti.l_budgets_libraries',
                          :foreign_key=>'budget_id',
                          :association_foreign_key=>[:budget_id, :clavis_library_id])

  has_many :clavis_libraries, :through=>:sbct_l_budget_libraries

  has_and_belongs_to_many(:sbct_suppliers, join_table:'sbct_acquisti.l_budgets_suppliers',
                          :foreign_key=>'budget_id',
                          :association_foreign_key=>'supplier_id')

  belongs_to :sbct_supplier, foreign_key:'supplier_id'

  def supplier_info
    self.sbct_supplier.nil? ? "nessuno" : self.sbct_supplier.to_label
  end

  def pac_libraries
    sql = "select * from public.pac_budgets where budget_id = #{self.id} order by library_name"
    SbctLBudgetLibrary.find_by_sql(sql)
  end

  def browse_object(cmd,ids)
    return if ids.nil?
    record_id=nil
    case cmd
    when 'prev'
      return nil if self.id == ids.first
      record_id = ids[ids.index(self.id)-1]
    when 'next'
      return nil if self.id == ids.last
      record_id = ids[ids.index(self.id)+1]
    when 'first'
      record_id = ids.first
    when 'last'
      record_id = ids.last
    else
      raise "browse_object('prev'|'next'|'first'|'last')"
    end
    # record_id.nil? ? nil : SbctBudget.find(record_id)
    record_id.nil? ? nil : self.class.send(:find, record_id)
  end

  def suppliers_report
    sql=%Q{select s.supplier_name,s.supplier_id,s.tipologie,count(DISTINCT ob.budget_id) as budgets_count,
  array_to_string(array_agg(DISTINCT ob.label order by ob.label), ', ') as supplier_for
  from sbct_acquisti.budgets b
   join  sbct_acquisti.l_budgets_suppliers lbs using(budget_id)
   join sbct_acquisti.suppliers s on(s.supplier_id=lbs.supplier_id)
   left join sbct_acquisti.l_budgets_suppliers olbs on (olbs.supplier_id=lbs.supplier_id)
   left join sbct_acquisti.budgets ob on(ob.budget_id=olbs.budget_id)
    where b.budget_id=#{self.id} and ob.locked is false group by 1,2 order by s.supplier_name}
    # puts sql
    SbctBudget.find_by_sql(sql)
  end

  def budget_report
    sql = %Q{select os.label as stato,cp.order_status,sum(cp.prezzo * cp.numcopie) as totale, sum(cp.numcopie) as numcopie
          from sbct_acquisti.copie cp join sbct_acquisti.order_status os on(os.id=cp.order_status)
         join sbct_acquisti.budgets b using(budget_id) where budget_id = #{self.id} group by os.label,cp.order_status;}
    puts sql
    SbctOrderStatus.find_by_sql(sql)
  end

  def importo_residuo(order_status_array=['A','O'])
    res = self.total_amount
    return if res.nil?
    self.budget_report.each do |e|
      res -= e.totale.to_f if order_status_array.include?(e.order_status)
    end
    res.to_f
  end

  def insert_l_budget_library
    cb = self.clavis_budget
    if cb.library_id > 1
      if !SbctLBudgetLibrary.exists?([self.id,cb.library_id])
        bl=SbctLBudgetLibrary.new(budget_id:self.id,clavis_library_id:cb.library_id)
        bl.quota=100
        bl.save
      end
    end
    true
  end

  def snapshot(library_ids=nil)
    h=Hash.new
    htmp=Hash.new
    parms = {budget_ids:self.id,arrivati_o_ordinati:true}
    if !library_ids.nil?
      tv = library_ids
      if tv.class==Array
        parms[:library_ids]=[tv]
      else
        parms[:library_ids]=[tv]
      end
    else
      library_id=self.clavis_budget.library_id
      if library_id==1
        parms[:library_ids]=self.clavis_libraries.collect{|l| l.id}
      else
        parms[:library_ids]=[self.clavis_budget.library_id]
      end
    end
    # parms = {budget_ids:self.id,order_status:'S'}
    # puts "chiamo SbctItem.items_per_libraries con parms #{parms}"
    SbctItem.items_per_libraries(parms).each do |e|
      # puts "QUI: #{e.inspect}"
      h[[e.siglabct,e.qb]]=e.ancora_disp.to_f
      htmp[[e.siglabct,e.qb]]=e
    end
    h.keys.each do |e|
      k=e.first
      if !h.has_key?([k,true])
        v = 100 - htmp[[k,false]].subquota.to_f
        x = htmp[[k,false]].totale_assegnato.to_f / 100 * v
        h[[k,true]]=x
      end
    end
    if h.size==0
      sql = "select * from public.pac_budgets where budget_id = #{self.id}"
      self.connection.execute(sql).each do |r|
        puts "r: #{r.inspect}"
        h[[r['siglabct'],false]] = r['partial_amount'].to_f
        h[[r['siglabct'],true]] = 0
      end
      return h
    end
    h
  end

  def suppliers
    sql = %Q{select s.supplier_id,s.supplier_name,sum(numcopie) as numcopie, sum(c.prezzo*c.numcopie) as importo,
   o.label as order_status
from sbct_acquisti.budgets b
   join sbct_acquisti.copie c using(budget_id) join sbct_acquisti.suppliers s on(s.supplier_id=c.supplier_id)
   join sbct_acquisti.order_status o on(o.id = c.order_status)
    where c.budget_id=#{self.id} group by s.supplier_id,s.supplier_name,o.label order by numcopie;}
    puts sql
    SbctSupplier.find_by_sql(sql)
  end

  def assegna_fornitori(supplier_ids)
    if !self.supplier_id.nil?
      # puts "Non assegno fornitori perché questo budget ha un fornitore associato: #{self.supplier_id}"
      return
    end
    puts "Assegno fornitori #{supplier_ids} alle copie con order_status 'S' del budget #{self.to_label}"
    # puts self.total_amount

    quota_fornitore = SbctSupplier.quota_fornitore('MiC22', 'MiC 2022')
    puts "Importo massimo per fornitore: #{quota_fornitore}"
    
    sql=%Q{select sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata 
          from sbct_acquisti.copie where budget_id = #{self.id} and supplier_id is not null and order_status ='S' and prezzo notnull;}
    cifra_impegnata = self.connection.execute(sql).to_a.first['cifra_impegnata'].to_f
    puts "Cifra impegnata: #{cifra_impegnata}"

    sql = %Q{select supplier_id,sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata
          from sbct_acquisti.copie where supplier_id in(#{supplier_ids.join(',')}) and order_status ='S' and prezzo notnull group by supplier_id;}
    puts sql
    hs=Hash.new
    self.connection.execute(sql).each do |r|
      hs[r['supplier_id'].to_i] = r['cifra_impegnata'].to_f
    end
    supplier_ids.each do |id|
      hs[id] = 0.0 if hs[id].nil?
    end
    puts hs.inspect
    
    sql=%Q{select id_copia,prezzo from sbct_acquisti.copie where budget_id = #{self.id} and supplier_id is null
          and order_status ='S' and prezzo notnull and prezzo < 100 ORDER BY prezzo;}
    puts sql
    i = -1
    len_i = supplier_ids.size - 1
    # puts "numero di fornitori: #{len_i}"
    sqli = []
    self.connection.execute(sql).to_a.each do |r|
      if (cifra_impegnata + r['prezzo'].to_f) > self.total_amount
        puts "FORSE salto assegnazione per budget #{self.to_label} (id_copia: #{r['id_copia']} - prezzo: #{r['prezzo']}) farebbe superare l'importo disponibile di #{self.total_amount}"
        # next
      end
      i = -1 if i >= len_i
      i += 1
      if (hs[supplier_ids[i]] + r['prezzo'].to_f) > quota_fornitore
        #  or (cifra_impegnata + r['prezzo'].to_f) > self.total_amount
        puts "NON ASSEGNO la copia #{r['id_copia']} - prezzo: #{r['prezzo']} al fornitore #{supplier_ids[i]} che ha già impegnato #{hs[supplier_ids[i]]} euro su #{quota_fornitore}"
      else
        s = "UPDATE sbct_acquisti.copie SET supplier_id=#{supplier_ids[i]} WHERE id_copia=#{r['id_copia']};"
        sqli << s
        hs[supplier_ids[i]] += r['prezzo'].to_f
        # puts "i = #{i} corrisponde a supplier #{supplier_ids[i]} (importo assegnato: #{hs[supplier_ids[i]]}) - #{s}"
        cifra_impegnata += r['prezzo'].to_f
      end
      # self.connection.execute(s)
    end
    self.connection.execute(sqli.join("\n"))
    puts "Per budget #{self.id} - #{self.to_label} : cifra_impegnata #{cifra_impegnata} (total_amount: #{self.total_amount})"
  end

  def conta_titoli_in_comune_con_altri_budget
    library_id = self.clavis_budget.library_id
    b = self.clavis_budget.budget_title
    sql = %Q{select count(*) from (
      select id_titolo from public.vedi_mic where budget_label ~ '^#{b}' and library_id=#{library_id}
       intersect
      select id_titolo from public.vedi_mic where budget_label ~ '^#{b}' and library_id!=#{library_id}) t;
    }
    self.connection.execute(sql).first['count'].to_i
  end

  def sbct_items
    SbctItem.items_per_libraries({budget_ids:self.id,arrivati_o_ordinati:true})
  end

  def sbct_items_count
    sql=%Q{select count(*) from sbct_acquisti.copie where budget_id=#{self.id};}
    self.connection.execute(sql).first['count'].to_i
  end
  
  def associa_a_lista_NONUSARE(sbct_list)
    sql = %Q{
     update sbct_acquisti.copie c set budget_id = #{self.id}
       from sbct_acquisti.liste l join sbct_acquisti.l_titoli_liste lt using(id_lista)
                where c.id_titolo=lt.id_titolo 
            and l.id_lista=#{sbct_list.id};
    }
    r=self.connection.execute(sql)
    r.cmd_tuples
  end

  def to_label
    label = self.label
    if !self.clavis_budget.nil?
      if !self.clavis_budget.clavis_library.nil?
        bib = clavis_budget.clavis_library.shortlabel.strip
        label << " - #{bib}" if !label.match(bib).to_s
      end
    end
    label
  end

  # DA NON USARE
  def spendi
    raise "Procedura disabilitata"
    raise "Questo budget non permette l'assegnazione automatica dei fornitori" if self.auto_assign_suppliers==false
    ids = self.sbct_suppliers.collect {|r| r.id}
       
    sql = %Q{UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE order_status='S' and budget_id = #{self.id}
        and supplier_id in (#{ids.join(',')});}

    sql = %Q{UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE order_status='S' and budget_id = #{self.id}}
    puts sql
    self.connection.execute(sql)
    return
  end

  def liste
    sql=%Q{select l.id_lista,l.data_libri,tt.tipo_titolo,l.label,count(l) as numero_copie
 from sbct_acquisti.liste l
       join sbct_acquisti.l_titoli_liste tl using(id_lista)
       join sbct_acquisti.copie c using(id_titolo)
       join sbct_acquisti.budgets b using(budget_id)
       join sbct_acquisti.tipi_titolo tt using(id_tipo_titolo)
       where b.budget_id=#{self.id}
       group by l.id_lista,l.data_libri,tt.tipo_titolo
       order by l.data_libri;}
    SbctList.find_by_sql(sql)
  end

  def siglabct
    s=ClavisLibrary.siglebct.key(self.library_id.to_i)
    return if s.nil?
    s.to_s.upcase
  end

  def allinea_prezzi_copie
    SbctBudget.allinea_prezzi_copie(self.id)
  end

  def SbctBudget.allinea_prezzi_copie(budget_id=nil)
    cond = budget_id.nil? ? '' : "AND budget_id=#{self.connection.quote(budget_id)}"
    sql = %Q{
      UPDATE sbct_acquisti.copie c set prezzo = t.prezzo
        FROM sbct_acquisti.titoli t WHERE c.prezzo is null and c.id_titolo=t.id_titolo and c.supplier_id is null and t.prezzo is not null #{cond};
      UPDATE sbct_acquisti.copie c set prezzo = t.prezzo
        FROM sbct_acquisti.titoli t WHERE c.supplier_id is null and c.id_titolo=t.id_titolo and t.prezzo!=c.prezzo and t.prezzo is not null #{cond};
    }
    puts sql
    self.connection.execute(sql)
  end

  def SbctBudget.associa_biblioteche(budgets)
    budgets.each do |r|
      next if r.library_id.nil?
      puts "budget per biblioteca #{r.library_id}: #{r.shortlabel} - #{r.total_amount}"
    end
    nil
  end

  def SbctBudget.tutti(params={},current_user)
    where = params[:budget_id].blank? ? "b.budget_id>0" : "b.budget_id=#{params[:budget_id]}"
    cond = []
    # cond << "c.order_status IN ('O','A')" if params[:all].blank?
    cond << (params[:locked].blank? ? "not b.locked" : "b.locked")
    cond << "b.label ~ #{SbctBudget.connection.quote(params[:label])}" if !params[:label].blank?
    cond << "b.auto_assign_suppliers is true" if params[:auto_assign_suppliers]==true
    cond << "cb.budget_title = #{SbctBudget.connection.quote(params[:budget_label])}" if !params[:budget_label].blank?
    if params[:supplier].blank?
      cond << "b.supplier_id is not null"
    else
      cond << "b.supplier_id is null"
    end
    # if current_user.role?('AcquisitionLibrarian') and !params[:supplier].blank?
    if current_user.role?('AcquisitionLibrarian')
      (
        ids=current_user.clavis_libraries.collect {|i| i.id}
        cond << "cb.library_id in(1,#{ids.join(',')})"
      )
    end
    if params[:selected].blank?
      orderstatus = "'A','O'"
    else
      orderstatus = "'S'"
    end
    
    cond = cond.size==0 ? '' : "AND #{cond.join(' AND ')}"

    sql=%Q{
select b.label, b.budget_id, count(s) as assegnate_a_fornitore, sum(c.numcopie) as numero_copie,
COALESCE((sum(c.prezzo * c.numcopie)),0) as impegnato,
to_char(avg(c.prezzo), 'FM999999999.00') as costo_medio,
b.total_amount,
b.total_amount - COALESCE((sum(c.prezzo * c.numcopie)),0) as importo_residuo
FROM sbct_acquisti.budgets b JOIN clavis.budget cb on(cb.budget_id=b.clavis_budget_id)
  left join sbct_acquisti.copie c on(c.budget_id=b.budget_id AND c.order_status in (#{orderstatus}))
  left join sbct_acquisti.titoli t using(id_titolo)
  left join sbct_acquisti.suppliers s on(s.supplier_id=c.supplier_id)
WHERE #{where} #{cond} group by b.label,b.budget_id
order by b.label;}
    fd=File.open("/home/seb/sbct_budgets.sql", "w")
    fd.write(sql)
    fd.close
    SbctBudget.find_by_sql(sql)
  end

  def SbctBudget.label_select(params={},user=nil)
    # filter = "and not ab.label ~* '^MiC'"
    filter = 'and ab.supplier_id notnull'
    # filter = ''
    if !user.nil?
      if SbctTitle.user_roles(user).include?('AcquisitionManager')
        filter = ''
      end
      if SbctTitle.user_roles(user).include?('AcquisitionStaffMember')
        filter = 'and ab.supplier_id notnull'
      end
    end
    if params[:mybudgets].blank?
      sql=%Q{select ab.budget_id as key,ab.label, ab.total_amount, trim(cl.shortlabel) as clavis_label
         from sbct_acquisti.budgets ab
            left join clavis.budget cb on (cb.budget_id=ab.clavis_budget_id) left join clavis.library cl using(library_id)
             where ab.label is not null #{filter} and ab.locked = false and cb.library_id in (1,#{params[:library_id].to_i}) order by ab.label;}
    else
      ids=user.clavis_libraries.collect {|i| i.id}
      sql=%Q{select b.budget_id as key,b.label as label
         FROM sbct_acquisti.budgets b JOIN clavis.budget cb on(cb.budget_id=b.clavis_budget_id)
         WHERE not b.locked AND cb.library_id in(1,#{ids.join(',')})
  	and cb.library_id in (1,#{params[:library_id].to_i}) order by b.label;}
    end
    fd=File.open("/home/seb/sbct_budgets_label_select.sql", "w")
    fd.write(sql)
    fd.close

    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = r['label']
      label << " (#{r['clavis_label']}, #{r['total_amount']} euro)" if !r['clavis_label'].nil?
      res << [label,r['key']]
    end
    if !params[:mybudgets].blank?
      res << ['Assegna automaticamente','autoassign']
    end
    res
  end

  def SbctBudget.azzera_fornitori_mic22
    raise 'Non utilizzabile!!!'
    supplier_ids = SbctSupplier.where("supplier_name ~ '^MiC22'").collect{|s| s.id}
    sql = %Q{
BEGIN;
UPDATE sbct_acquisti.copie SET order_id = NULL, order_status='S' WHERE order_id is not null AND supplier_id in (#{supplier_ids.join(',')});
UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE supplier_id in (#{supplier_ids.join(',')});
COMMIT;
    }
    puts sql
    self.connection.execute(sql)
  end

  def SbctBudget.loop_assegna_fornitori(order_by_prezzo='asc',budget_ids=[], supplier_ids=[], sql_spec='')
    raise "SbctBudget.loop_assegna_fornitori NON UTILIZZABILE (è stato usato nel 2022)"
    while SbctBudget.assegna_fornitori(order_by_prezzo,budget_ids,supplier_ids,sql_spec) > 0 do
      # SbctBudget.assegna_fornitori('asc')
      SbctBudget.assegna_fornitori('asc',budget_ids,supplier_ids,sql_spec)
    end
  end

  def SbctBudget.assegna_fornitori(order_by_prezzo='desc',budget_ids=[], supplier_ids=[], sql_spec='')
    raise "SbctBudget.assegna_fornitori NON UTILIZZABILE (è stato usato nel 2022)"
    puts "Entro in SbctBudget.assegna_fornitori con sql_spec: #{sql_spec}"

    #supplier_ids = SbctSupplier.where("supplier_name ~ '^MiC22' and supplier_id!=154").collect{|s| s.id}
    #sql = "UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE supplier_id in (#{supplier_ids.join(',')});"
    #puts sql
    #self.connection.execute(sql)

    supplier_ids = SbctSupplier.where("supplier_name ~ '^MiC22'").collect{|s| s.id} if supplier_ids.size==0
    budget_ids = SbctBudget.where("label ~ '^MiC 2022'").collect{|s| s.id} if budget_ids.size==0

    
=begin
    sql = "UPDATE sbct_acquisti.copie SET order_date = NULL WHERE supplier_id in (#{supplier_ids.join(',')}) and budget_id in (#{budget_ids.join(',')});"
    puts sql
    self.connection.execute(sql)
    sql = "UPDATE sbct_acquisti.copie SET order_status = 'S' WHERE supplier_id in (#{supplier_ids.join(',')}) and order_status='O' and budget_id in (#{budget_ids.join(',')});"
    puts sql
    self.connection.execute(sql)
    sql = "UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE supplier_id in (#{supplier_ids.join(',')}) and budget_id in (#{budget_ids.join(',')});"
    puts sql
    self.connection.execute(sql)
=end

    quota_fornitore = SbctSupplier.quota_fornitore('MiC22', 'MiC 2022')
    puts "Importo massimo per fornitore: #{quota_fornitore}"

    # Verificare se non sia il caso di aggiungere 'A' tra gli order_status da considerare qui:
    sql = %Q{select supplier_id,sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata
          from sbct_acquisti.copie where supplier_id in(#{supplier_ids.join(',')}) 
          and order_status IN ('O','S','A')
          and prezzo notnull group by supplier_id;}
    puts sql

    hs=Hash.new
    self.connection.execute(sql).each do |r|
      hs[r['supplier_id'].to_i] = r['cifra_impegnata'].to_f
    end
    puts hs.inspect
    supplier_ids.each do |id|
      hs[id] = 0.0 if hs[id].nil?
    end
    puts "Stato iniziale dei fornitori: #{hs.inspect}"
    numsuppliers = hs.size
    # puts "numsuppliers: #{numsuppliers}"

    sql = %Q{select budget_id,sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata
          from sbct_acquisti.copie where budget_id in(#{budget_ids.join(',')})
           and order_status IN ('O','S') and supplier_id is not null AND prezzo is not null group by budget_id;}
    puts sql

    hb=Hash.new
    self.connection.execute(sql).each do |r|
      hb[r['budget_id'].to_i] = r['cifra_impegnata'].to_f
    end
    puts "Stato iniziale dei budgets: #{hb.inspect}"
    budget_ids.each do |id|
      hb[id] = 0.0 if hb[id].nil?
    end
    puts "Stato iniziale dei budgets: #{hb.inspect}"

    sql = %Q{select budget_id,total_amount from sbct_acquisti.budgets where budget_id in(#{budget_ids.join(',')})}
    puts sql

    ha=Hash.new
    self.connection.execute(sql).each do |r|
      ha[r['budget_id'].to_i] = r['total_amount'].to_f
    end
    puts "Cifra impegnabile per budget: #{ha.inspect}"
    # return ha
    sql_spec = sql_spec.blank? ? '' : "AND #{sql_spec}"
    sql = %Q{
with multicopia as
(    
    select c.id_titolo,count(*) as numero_copie from sbct_acquisti.copie c
     join sbct_acquisti.titoli t using(id_titolo)
     where budget_id in (#{budget_ids.join(',')}) and c.order_status='S'
     and c.supplier_id is null and t.prezzo is not null #{sql_spec}
         group by c.id_titolo
)
     select mc.numero_copie,t.prezzo as prezzo_titolo,c.* from sbct_acquisti.copie c
       join sbct_acquisti.titoli t using(id_titolo)
       join multicopia mc on(mc.id_titolo=c.id_titolo)
       where budget_id in (#{budget_ids.join(',')})
       and c.supplier_id is null and c.prezzo is not null
       order by mc.numero_copie desc, c.prezzo #{order_by_prezzo}, t.id_titolo;
  }
    puts sql
    
    i = -1
    len_i = supplier_ids.size - 1
    count_down = assegnate = 0
    sqli = []
    self.connection.execute(sql).to_a.each do |r|
      if count_down == 0
        count_down = r['numero_copie'].to_i
        i = -1 if i >= len_i
        i += 1
        # puts "=> #{r['numero_copie']} copie per il titolo #{r['id_titolo']} con prezzo #{r['prezzo']}"
      end
      count_down -= 1
      # puts " => count_down: #{count_down} / i: #{i} / copia #{r['id_copia']} / prezzo: #{r['prezzo']} / fornitore #{supplier_ids[i]} / impegnato #{hs[supplier_ids[i]].round(2)} euro su #{quota_fornitore}"
      prezzo = r['prezzo'].to_f
      numcopie = r['numcopie'].to_i
      if (hs[supplier_ids[i]] + prezzo * numcopie) > quota_fornitore
        puts "NON ASSEGNO la copia #{r['id_copia']} - prezzo: #{prezzo} al fornitore #{supplier_ids[i]} che ha già impegnato #{hs[supplier_ids[i]].round(2)} euro su #{quota_fornitore}" if numcopie > 1
      else
        budget_id = r['budget_id'].to_i
        if (hb[budget_id] + prezzo * numcopie) > ha[budget_id]
          # puts "Non assegno copia #{r['id_copia']} - prezzo: #{prezzo} al budget_id #{budget_id} : importo budget #{ha[budget_id]} (già assegnati #{hb[budget_id].round(2)} euro)"
        else
          s = "UPDATE sbct_acquisti.copie SET supplier_id=#{supplier_ids[i]} WHERE id_copia=#{r['id_copia']};"
          puts s
          sqli << s
          hs[supplier_ids[i]] += prezzo * numcopie
          hb[budget_id] += prezzo * numcopie
          # puts "i = #{i} supplier #{supplier_ids[i]} (importo: #{hs[supplier_ids[i]].round(2)}) - budget_id: #{budget_id} (importo: #{hb[budget_id].round(2)} su #{ha[budget_id]})"
          assegnate += 1
        end
      end
    end
    # self.connection.execute(sqli.join("\n"))
    puts "Esco da assegna_fornitori - assegnate #{assegnate} copie"
    assegnate
  end

  def SbctBudget.titles(budget_title)
    # self.connection.execute("UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE order_status='S' and budget_id = 35")
    sql = %Q{select count(c.budget_id) as numero_copie,array_to_string(array_agg(c.budget_id order by c.budget_id),',') as budget_ids,
array_to_string(array_agg(c.id_copia order by c.budget_id),',') as copie_ids,
array_to_string(array_agg(c.prezzo order by c.budget_id),',') as prezzi_copie,
      t.id_titolo,t.prezzo,concat_ws(' ; ',t.keywords,t.reparto,t.sottoreparto) as qualificazioni
  from sbct_acquisti.titoli t join sbct_acquisti.copie c using(id_titolo)
  join sbct_acquisti.budgets b using(budget_id)
  join clavis.budget cb on (cb.budget_id = b.clavis_budget_id)
   WHERE cb.budget_title = #{self.connection.quote(budget_title)} and c.prezzo is not null
         and b.auto_assign_suppliers=true
            group by t.id_titolo
              -- having count(c.budget_id) <= 6
        order by numero_copie desc, budget_ids, t.id_titolo}
    puts sql
    SbctTitle.find_by_sql(sql)
  end

  def SbctBudget.preassegna_fornitori_qualificati(budget_title)
    sql = %Q{create or replace view sbct_acquisti.suppliers_tipologie as
select supplier_id, unnest(string_to_array(tipologie, ' ; ')) as tipologia from
 sbct_acquisti.suppliers s
   where s.supplier_name ~ '^#{budget_title}';
   with t1 as
(
select t.id_titolo,
    array_agg(distinct c.budget_id order by c.budget_id) as budget_ids,
      concat_ws(' ; ',t.keywords,t.reparto,t.sottoreparto) as qualificazioni_titolo,
      fq.tipologia as tipologia_fornitore,
      array_to_string(array_agg(distinct fq.supplier_id),',') as supplier_ids
  from sbct_acquisti.titoli t join sbct_acquisti.copie c using(id_titolo)
  join sbct_acquisti.budgets b using(budget_id)
  join clavis.budget cb on (cb.budget_id = b.clavis_budget_id)
  join sbct_acquisti.suppliers_tipologie fq on(concat_ws(' ; ',t.keywords,t.reparto,t.sottoreparto) ~ fq.tipologia)
   where 
      cb.budget_title = 'MiC23' and b.auto_assign_suppliers=true
group by t.id_titolo,fq.tipologia
)
select array_to_string(budget_ids,',') as budget_ids,  supplier_ids from t1 where array_length(budget_ids,1) > 1 order by array_length(budget_ids,1) desc,budget_ids
-- select * from t1;}
    puts sql

    budgets = SbctBudget.find_by_sql("select budget_id from sbct_acquisti.budgets where auto_assign_suppliers is true and label ~ '^#{budget_title}'")
    budget_ids = budgets.collect {|r| r.id}
    budgets.each {|r| r.num_fornitori_preassegnati=0}
    puts "Preassegno al massimo 3 fornitori a ognuno di questi budget: #{budgets.size} - #{budget_ids}"
    res = self.connection.execute(sql)
    res.each do |r|
      b_ids = r['budget_ids']
      s_ids = r['supplier_ids']
      # puts "Prendo in esame questo gruppo di budget: #{b_ids} che condividono questi potenziali fornitori: #{s_ids}"
      b_ids.split(',').each do |b|
        b = b.to_i
        b_corrente=nil
        budgets.each {|x| b_corrente=x if x.id==b}
        # next if b_corrente.num_fornitori_preassegnati >= 3
        # puts "budget corrente: #{b_corrente.id} - num_fornitori_preassegnati è #{b_corrente.num_fornitori_preassegnati}"
        s_ids.split(',').each do |s|
          sql = "INSERT INTO sbct_acquisti.l_budgets_suppliers(budget_id,supplier_id) (select #{b},#{s}) on conflict do nothing;"
          # puts sql
          self.connection.execute(sql)
          b_corrente.num_fornitori_preassegnati += 1
          # break if b_corrente.num_fornitori_preassegnati >= 3
        end
        # puts "ora budget corrente: #{b_corrente.id} - num_fornitori_preassegnati è #{b_corrente.num_fornitori_preassegnati}"
      end
    end
  end

  def SbctBudget.preassegna_fornitori(budget_title)
    sql = %Q{with t1 as
(
select t.id_titolo,
    array_agg(distinct c.budget_id order by c.budget_id) as budget_ids,
      concat_ws(' ; ',t.keywords,t.reparto,t.sottoreparto) as qualificazioni_titolo,
      array_to_string(array_agg(distinct s.supplier_id),',') as supplier_ids
  from sbct_acquisti.titoli t join sbct_acquisti.copie c using(id_titolo)
  join sbct_acquisti.budgets b using(budget_id)
  join clavis.budget cb on (cb.budget_id = b.clavis_budget_id)
  join sbct_acquisti.suppliers s on(s.supplier_name ~ '^MiC23' and s.tipologie is null)
   where 
      cb.budget_title = 'MiC23' and b.auto_assign_suppliers=true
group by t.id_titolo
)
select array_to_string(budget_ids,',') as budget_ids,  supplier_ids from t1 where array_length(budget_ids,1) > 1 order by array_length(budget_ids,1) desc,budget_ids}
    puts sql

    budgets = SbctBudget.find_by_sql("select budget_id from sbct_acquisti.budgets where auto_assign_suppliers is true and label ~ '^#{budget_title}'")
    budget_ids = budgets.collect {|r| r.id}
    budgets.each {|r| r.num_fornitori_preassegnati=0}
    puts "Preassegno fornitori a ognuno di questi budget: #{budgets.size} - #{budget_ids}"
    res = self.connection.execute(sql)
    res.each do |r|
      b_ids = r['budget_ids']
      s_ids = r['supplier_ids']
      # puts "Prendo in esame questo gruppo di budget: #{b_ids} che condividono questi potenziali fornitori: #{s_ids}"
      b_ids.split(',').each do |b|
        b = b.to_i
        b_corrente=nil
        budgets.each {|x| b_corrente=x if x.id==b}
        # next if b_corrente.num_fornitori_preassegnati >= 3
        # puts "budget corrente: #{b_corrente.id} - num_fornitori_preassegnati è #{b_corrente.num_fornitori_preassegnati}"
        s_ids.split(',').each do |s|
          sql = "INSERT INTO sbct_acquisti.l_budgets_suppliers(budget_id,supplier_id) (select #{b},#{s}) on conflict do nothing;"
          # puts sql
          self.connection.execute(sql)
          b_corrente.num_fornitori_preassegnati += 1
          # break if b_corrente.num_fornitori_preassegnati >= 3
        end
        # puts "ora budget corrente: #{b_corrente.id} - num_fornitori_preassegnati è #{b_corrente.num_fornitori_preassegnati}"
      end
    end
  end

  def SbctBudget.suddividi(budget_title)
    # self.connection.execute("delete from sbct_acquisti.l_budgets_suppliers where budget_id != 33")
    # select budget_id,array_agg(supplier_id order by supplier_id),count(*) from l_budgets_suppliers group by 1 order by budget_id;

    raise "non utilizzabile dal 9 ottobre 2023"
    
    titles=SbctBudget.titles(budget_title)
    puts "Tutti i titoli di #{budget_title} sono nell'array titles: #{titles.size}"
    i={}
    titles.each do |t|
      t.budget_ids.split(',').each {|b| i[b.to_i]=true}
    end
    all_budget_ids = i.keys.join(',')

    sq = "select budget_id,id_titolo,count(*) from sbct_acquisti.copie where budget_id in(#{all_budget_ids}) group by 1,2 having count(*) > 1;"
    self.connection.execute(sq).to_a.each do |r|
      puts "ATTENZIONE: #{r.inspect}"
      raise "copie doppie, non va bene"
    end

    #self.connection.execute("delete from sbct_acquisti.l_budgets_suppliers where budget_id!=33")
    #SbctBudget.preassegna_fornitori_qualificati(budget_title)
    #SbctBudget.preassegna_fornitori(budget_title)
    #self.connection.execute("delete from sbct_acquisti.l_budgets_suppliers where supplier_id in (526,527) and budget_id!=33")

    sql = %Q{
    SELECT * FROM sbct_acquisti.suppliers WHERE supplier_id IN 
      (SELECT distinct supplier_id FROM sbct_acquisti.l_budgets_suppliers where budget_id in (#{all_budget_ids}))
    }
    puts "budget_ids interessati: #{all_budget_ids}"

    all_suppliers = SbctSupplier.find_by_sql(sql)
    quota_fornitore=all_suppliers.first.quota_fornitore
    fornitori_residuo=0.0
    all_suppliers.each do |s|
      s.residuo=quota_fornitore
      fornitori_residuo += s.residuo
    end
    SbctOrder.azzera_ordini_per_fornitori(all_suppliers)

    fornitori_residuo = fornitori_residuo.round(2)
    puts "Tutti i #{all_suppliers.size} fornitori - importo da assegnare: #{fornitori_residuo} sono nell'array all_suppliers"
    puts "Quota da assegnare a ogni fornitore #{quota_fornitore}"

    sql = "SELECT supplier_id,(array_agg(budget_id))[1] as budget_id FROM sbct_acquisti.l_budgets_suppliers where budget_id in (#{all_budget_ids}) group by supplier_id having count(*)=1"
    esclusivi = SbctSupplier.find_by_sql(sql).collect {|s| s.budget_esclusivo=s.budget_id.to_i;s}
    qualificati = all_suppliers.collect {|s| s if !s.tipologie.nil?}.compact
    generalisti = all_suppliers.collect {|s| s if s.tipologie.nil?}.compact
    
    puts "Fornitori 'qualificati': #{qualificati.size}, nell'array 'qualificati'"
    puts "Fornitori 'generalisti': #{generalisti.size}, nell'array 'generalisti'"
    puts "Fornitori esclusivi: #{esclusivi.size}: #{esclusivi.inspect}"

    sql = "select * FROM sbct_acquisti.pac_importi_assegnabili where budget_id IN (#{all_budget_ids})"
    all_budgets = SbctBudget.find_by_sql(sql)
    bhash={}
    budgets_totale_assegnato=0.0
    budgets_totale_da_spendere=0.0
    all_budgets.each do |b|
      b.residuo=b.assegnabile.to_f
      bhash[b.id] = b
      budgets_totale_da_spendere += b.residuo
    end
    budgets_totale_da_spendere = budgets_totale_da_spendere.round(2)
    puts "I budgets da utilizzare sono #{all_budgets.size} per un totale di #{budgets_totale_da_spendere} da spendere"

    puts "Inizio assegnando le copie ai fornitori qualificati (tipo RAGAZZI, FUMETTI etc)"
    puts "Fornitori 'qualificati': #{qualificati.size}, nell'array 'qualificati'"
    kwords = []
    qualificati.each do |s|
      # puts s.tipologie
      s.tipologie.split(';').each do |k|
        kwords << k.strip
      end
    end
    kwords.uniq!
    puts "kwords: #{kwords.inspect}"
    puts "Dunque dei #{titles.count} titoli, considero solo quelli che dovrebbero essere assegnati a fornitori qualificati"

    newtitles = Array.new
    generic_titles = Array.new
    titles.each do |t|
      aggiunto = nil
      if !t.qualificazioni.blank?
        t.qualificazioni.split(';').each do |k|
          k.strip.split(',').each do |w|
            w.strip!
            # puts "id_titolo #{t.id_titolo} contiene #{w} da confrontare con #{kwords}"
            if kwords.include?(w) and aggiunto.nil?
              aggiunto = true
              newtitles << t
            end
          end
        end
      end
      generic_titles << t if aggiunto.nil?
    end
    fd = File.open("/tmp/assegna.sql","w")

    da_assegnare = []
    # prima=bhash[35].residuo
    puts "Ho individuato #{newtitles.size} titoli che sono qualificati come #{kwords} e #{generic_titles.size} generici"
    bhash,non_assegnati,budgets_totale_assegnato,fornitori_residuo = SbctBudget.assegna_copie_a_fornitori(fd,newtitles,all_suppliers,qualificati,esclusivi,bhash,fornitori_residuo,budgets_totale_assegnato)
    da_assegnare << non_assegnati
    puts "Ora assegno i titoli generalisti ai rispettivi fornitori"
    bhash,non_assegnati,budgets_totale_assegnato,fornitori_residuo = SbctBudget.assegna_copie_a_fornitori(fd,generic_titles,all_suppliers,generalisti,esclusivi,bhash,fornitori_residuo,budgets_totale_assegnato)
    da_assegnare << non_assegnati
    puts "FINE assegnazioni, restano da assegnare #{da_assegnare.class} - #{da_assegnare.size}"

    fd.write("-- Assegnazioni finali\nBEGIN;\n")
    puts "assegnazioni finali da adesso in poi:"
    da_assegnare.each do |a|
      a.each do |r|
        id_titolo,budget_id=r
        t = SbctTitle.find(id_titolo)
        qualificazioni = t.compatta_qualificazioni
        puts "Esamino titolo #{t.id_titolo}, prezzo #{t.prezzo} per il budget #{budget_id} - con residuo #{bhash[budget_id].residuo.round(2)}"
        if (bhash[budget_id].residuo - t.prezzo) < 0
          puts "Achtung2: budget #{budget_id} esaurito e titolo #{t.id_titolo} scartato!"
          next
        end
        suppl = all_suppliers
        if esclusivi.include?(budget_id)
          puts "Questo budget #{budget_id} è esclusivo e può usare solo questi fornitori: #{esclusivi.collect{|s| s.id}}"
        else
          puts "Questo budget #{budget_id} NON è esclusivo e NON può usare questi fornitori: #{esclusivi.collect{|s| s.id}}"
          suppl = all_suppliers - esclusivi
        end
        supplier=nil
        suppl.each do |s|
          puts "D - Considero fornitore #{s.id}: residuo #{s.residuo.round(2)}"
          if s.esclusivo_per_tipologia
            if self.connection.execute("select tipologia from sbct_acquisti.suppliers_tipologie where supplier_id=#{s.id} and #{self.connection.quote(qualificazioni)}  ~* tipologia").count == 0
              puts "Importante: il fornitore #{s.id} vale solo per le tipologie #{s.tipologie} e questo titolo non è idoneo: lo salto (#{t.id_titolo} #{qualificazioni}) e considero il prossimo eventuale fornitore"
              next
            end
          end
          if (s.residuo - t.prezzo) > 0
            supplier = s
            break
          end
        end
        if supplier.nil?
          puts "Nessun fornitore trovai! scarto titolo #{t.id_titolo} destinato a budget #{budget_id}"
          next
        end
        bhash[budget_id].residuo -= t.prezzo
        supplier.residuo -= t.prezzo
        budgets_totale_assegnato += t.prezzo
        fornitori_residuo -= t.prezzo
        puts "Assegno copia per titolo #{t.id_titolo} con prezzo #{t.prezzo} al budget #{budget_id} - con residuo #{bhash[budget_id].residuo.round(2)}"
        sql = "-- residuo budget: #{bhash[budget_id].residuo.round(2)} - residuo fornitore: #{supplier.residuo.round(2)}\nUPDATE sbct_acquisti.copie set supplier_id=#{supplier.id} where supplier_id is null and id_titolo=#{t.id_titolo} and order_status='S' and budget_id=#{budget_id};\n"
        fd.write(sql)
      end
    end
    fd.write("COMMIT;\n")
    fd.close
    sql = File.read("/tmp/assegna.sql")
    puts "eseguo sql da file"
    self.connection.execute(sql)
    SbctOrder.trasforma_copie_selezionate_in_ordini(budget_title)
    true
  end

  def SbctBudget.raggruppa(budget_ids, qualificazioni_titolo)
    join_type = qualificazioni_titolo.nil? ? 'left join' : 'join'
    puts "Entrato in raggruppa con budget_ids = #{budget_ids} e qualificazioni_titolo #{qualificazioni_titolo}"
    sql = %Q{select l.supplier_id,fq.tipologia,s.tipologie,
     array_to_string(array_agg(distinct l.budget_id order by l.budget_id), ',')
        as budget_ids, count(l.budget_id)
 from sbct_acquisti.l_budgets_suppliers l join sbct_acquisti.budgets b using(budget_id)
 join sbct_acquisti.suppliers s on(s.supplier_id=l.supplier_id)
 #{join_type} sbct_acquisti.suppliers_tipologie fq on 
    ((#{self.connection.quote(qualificazioni_titolo)} ~ fq.tipologia) and (s.tipologie ~ fq.tipologia))
 where l.budget_id in (#{budget_ids.join(',')}) AND b.auto_assign_suppliers=true
 group by l.supplier_id,fq.tipologia,s.tipologie order by count(l.budget_id) desc, l.supplier_id;}
    # puts sql
    gruppi = SbctBudget.find_by_sql(sql)
    return gruppi if qualificazioni_titolo.nil?
    if gruppi.size==0
      puts "Non avendo trovato fornitori per il titolo #{qualificazioni_titolo} cerco quello generici..."
      gruppi = SbctBudget.raggruppa(budget_ids,nil)
    end
    puts "Individuati #{gruppi.size} gruppi di budget omogenei per qualificazioni titolo  '#{qualificazioni_titolo}'"
    all_suppliers = []
    if !qualificazioni_titolo.nil?
      all_suppliers = gruppi.collect {|r| r.supplier_id}.uniq
    end
    puts "all_suppliers in raggruppa: #{all_suppliers.inspect}"
    h = Hash.new
    cnt=0
    ok_suppliers = []

    gruppi.each do |g|
      break if budget_ids == []
      puts "cnt #{cnt+1} - #{g.supplier_id} => #{g.budget_ids} - #{g.tipologia} ----- qualificazioni_titolo: #{qualificazioni_titolo}"
      ids = []
      g.budget_ids.split(',').each do |b|
        b = b.to_i
        ids << b if budget_ids.include?(b)
        budget_ids.delete b
      end
      next if ids==[]
      cnt += 1
      # raise "cnt maggiore di 1 qui" if cnt>1
      myarray = Array.new(all_suppliers)
      myarray.delete g.supplier_id
      h[cnt] = {'s'=>g.supplier_id,'t'=>g.tipologia,'b'=>ids,'a'=>myarray}
    end
    return h
  end
    
  def SbctBudget.assegna_copie_a_fornitori(fd,titles,all_suppliers,suppliers_list,esclusivi,bhash,fornitori_residuo,budgets_totale_assegnato)
    puts "Sono ora in assegna_copie_a_fornitori per #{titles.size} titoli da assegnare a #{suppliers_list.size} fornitori - fornitori_residuo: #{fornitori_residuo} - esclusivi: #{esclusivi.inspect}"
    budgets_esclusivi=esclusivi.collect{|s| s.budget_esclusivo}.uniq
    sql=[]
    cnt = 0
    non_assegnati = []
    # t=titles.shift
    while titles.size>0
      t=titles.shift
      if t.prezzo.nil?
        raise "Prezzo mancante per titolo #{t.id_titolo}"
      end
      budget_ids = t.budget_ids.split(',').collect {|i| i.to_i}
      puts "----> #{t.id_titolo} : #{budget_ids} (#{t.numero_copie} copie) [#{t.qualificazioni}] prezzo: #{t.prezzo}"
      gruppi = SbctBudget.raggruppa(budget_ids,t.qualificazioni)
      # gruppi = SbctBudget.raggruppa(budget_ids,'MANGA')
      
      tit_prezzo = t.prezzo.to_f
      # puts "classe prezzo #{tit_prezzo.class}"
      puts "gruppi trovati: #{gruppi.size}"
      gruppi.each do |gr|
        gr_cnt = gr.first
        puts "    >> gruppo #{gr_cnt} di #{gruppi.size} ---> fornitore #{gr.inspect} - #{gr.last['s']}"
        budget_ids = gr.last['b']
        # raise "budget_ids: #{budget_ids} class #{budget_ids.class}"
        budget_ids.each do |budget_id|
          budget_id = budget_id.to_i
          puts "Titolo #{t.id_titolo} - copia con budget #{budget_id} residuo #{bhash[budget_id].residuo.round(2)}"
          if (bhash[budget_id].residuo - tit_prezzo) < 0
            puts "Achtung: budget #{budget_id} esaurito (tit_prezzo #{tit_prezzo} e budget.residuo #{bhash[budget_id].residuo}"
          next
          end
          suppliers = suppliers_list.collect {|s| s if s.id==gr.last['s']}.compact
          puts "#{suppliers.size} possibili fornitori DAL GRUPPO per questo budget #{budget_id}: #{suppliers.collect{|i| i.id}.compact}"
          supplier=nil
          suppliers.each do |s|
            puts "A - Considero fornitore #{s.id}: residuo #{s.residuo.round(2)}"
            if (s.residuo - tit_prezzo) > 0
              supplier = s
              break
            end
          end
          if supplier.nil?
            puts "Non posso usare fornitori dal gruppo, cerco negli altri nel campo 'a' di gr: #{gr.last['a']}"
            ids = gr.last['a'].collect {|s| s}
            suppliers = suppliers_list.collect {|s| s if ids.include?(s.id)}.compact
            puts "#{suppliers.size} possibili ALTRI fornitori DAL GRUPPO: #{suppliers.collect{|i| i.id}.compact}"
            supplier=nil
            suppliers.each do |s|
              puts "B - Considero fornitore #{s.id}: residuo #{s.residuo.round(2)}"
              if (s.residuo - tit_prezzo) > 0
                supplier = s
                break
              end
            end
            if supplier.nil?
              puts "Non posso usare neanche negli altri del campo 'a' di gr: #{gr.last['a']}"
              ids = bhash[budget_id].sbct_suppliers.collect {|s| s.id}
              suppliers = suppliers_list.collect {|s| s if ids.include?(s.id)}.compact
              puts "#{suppliers.size} possibili ultimi fornitori per questo budget #{budget_id}: #{suppliers.collect{|i| i.id}.compact}"
              supplier=nil
              suppliers.each do |s|
                puts "C - Considero fornitore #{s.id}: residuo #{s.residuo.round(2)}"
                if (s.residuo - tit_prezzo) > 0
                  supplier = s
                  break
                end
              end
            end
          end

          if supplier.nil?
            puts "No supplier, next gruppo se esiste un gruppo successivo"
            next if gruppi.size > gr_cnt
          end
          if supplier.nil?
            puts "Nessun fornitore sembra disponibile, ne cerco uno al di fuori di quelli preassegnati (budget: #{budget_id}) - #{all_suppliers.size} suppliers papabili: #{all_suppliers.collect{|i| i.id}.compact}"
            puts "gli esclusivi li considero solo se il budget corrente #{budget_id} è tra quelli esclusivi"
            suppl = all_suppliers
            if budgets_esclusivi.include?(budget_id)
              puts "Questo budget #{budget_id} è esclusivo e può usare solo questi fornitori: #{esclusivi.collect{|s| s.id}}"
            else
              puts "Questo budget #{budget_id} NON è esclusivo e NON può usare questi fornitori: #{esclusivi.collect{|s| s.id}}"
              suppl = all_suppliers - esclusivi
            end
            puts "suppl.size #{suppl.size}"

            s = suppl.sort_by {|x| x.residuo}.reverse.first
            if (s.residuo - tit_prezzo) > 0
              supplier = s
              puts "Aggiungo ai preassegnati per budget #{budget_id} il fornitore #{s.id}"
              sq = "INSERT INTO sbct_acquisti.l_budgets_suppliers(budget_id,supplier_id) (select #{budget_id},#{s.id}) on conflict do nothing;"
              self.connection.execute("delete from sbct_acquisti.l_budgets_suppliers where supplier_id in (526,527) and budget_id!=33")
              puts sq
              self.connection.execute(sq)
            else
              puts "Non ho trovato nessun fornitore davvero, aggiungo a non_assegnati #{t.id_titolo}/#{budget_id}"
              non_assegnati << [t.id_titolo,budget_id]
              next
            end
          end
          if supplier.esclusivo_per_tipologia
            if self.connection.execute("select tipologia from sbct_acquisti.suppliers_tipologie where supplier_id=#{supplier.id} and #{self.connection.quote(t.qualificazioni)}  ~* tipologia").count == 0
              puts "Importante: il fornitore #{supplier.id} vale solo per le tipologie #{supplier.tipologie} e questo titolo non è idoneo e lo salto (#{t.id_titolo} #{t.qualificazioni})"
              non_assegnati << [t.id_titolo,budget_id]
              next
            end
          end
          puts "Ok fornitore #{supplier.id} titolo #{t.qualificazioni} specializzazione fornitore #{supplier.tipologie} - esclusivo? #{supplier.esclusivo_per_tipologia} -residuo: #{supplier.residuo}"
          prezzo_copia = t.prezzi_copie.split(',').collect{|p| p.to_f}.compact.uniq
          if prezzo_copia.size>1
            raise "GROSSO ERRORE per titolo #{t.id_titolo}: #{prezzo_copia} difforme da #{tit_prezzo}"
          end
          if prezzo_copia.first != tit_prezzo
            puts "CLASS: #{prezzo_copia.first.class} CLASST: #{tit_prezzo.class}  Prezzo #{prezzo_copia.first} differisce da quello del titolo #{t.id_titolo} che risulta essere #{tit_prezzo}"
            raise "test"
          end
          # puts "prezzo_copia: #{prezzo_copia}"
          bhash[budget_id].residuo -= tit_prezzo
          supplier.residuo -= tit_prezzo
          fornitori_residuo -= tit_prezzo
          budgets_totale_assegnato += tit_prezzo
          cnt += 1
          puts "#{cnt} Assegno copia con prezzo #{tit_prezzo} id_titolo #{t.id_titolo} e budget_id #{budget_id} prezzo #{tit_prezzo} a #{supplier.id} - residuo fornitore: #{supplier.residuo.round(2)} - residuo budget: #{bhash[budget_id].residuo.round(2)}"
          sql << "-- prezzo: #{tit_prezzo} - residuo budget: #{bhash[budget_id].residuo.round(2)} - residuo fornitore: #{supplier.residuo.round(2)} qualiftitolo #{t.qualificazioni} - qforn #{supplier.tipologie}\nUPDATE sbct_acquisti.copie set supplier_id=#{supplier.id} where supplier_id is null and id_titolo=#{t.id_titolo} and order_status='S' and budget_id=#{budget_id};"
        end
        # break if cnt > 1
      end
    end
    sql = sql.join("\n")
    fd.write("-- #{cnt} assegnazioni\nBEGIN;\n#{sql}\nCOMMIT;\n")
    puts "Fine assegnazioni: budgets_totale_assegnato = #{budgets_totale_assegnato} - fornitori_residuo: #{fornitori_residuo}"
    return [bhash,non_assegnati,budgets_totale_assegnato,fornitori_residuo]
  end
end
