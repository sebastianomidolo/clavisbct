# coding: utf-8
class SbctBudget < ActiveRecord::Base

  self.table_name='sbct_acquisti.budgets'
  attr_accessible :clavis_budget_id, :supplier_id

  belongs_to :clavis_budget

  has_and_belongs_to_many(:clavis_libraries, join_table:'sbct_acquisti.l_budgets_libraries',
                          :foreign_key=>'budget_id',
                          :association_foreign_key=>'clavis_library_id')

  belongs_to :sbct_supplier, foreign_key:'supplier_id'

  def supplier_info
    self.sbct_supplier.nil? ? "nessuno" : self.sbct_supplier.to_label
  end

  def budget_report
    sql = %Q{select os.label as stato,cp.order_status,sum(cp.prezzo * cp.numcopie) as totale, sum(cp.numcopie) as numcopie
          from sbct_acquisti.copie cp join sbct_acquisti.order_status os on(os.id=cp.order_status)
         join sbct_acquisti.budgets b using(budget_id) where budget_id = #{self.id} group by os.label,cp.order_status;}
    puts sql
    SbctOrderStatus.find_by_sql(sql)
  end

  def suppliers
    sql = %Q{select s.supplier_id,s.supplier_name,sum(numcopie) as numcopie, sum(c.prezzo*c.numcopie) as importo,
   o.label as order_status
from sbct_acquisti.budgets b
   join sbct_acquisti.copie c using(budget_id) join sbct_acquisti.suppliers s on(s.supplier_id=c.supplier_id)
   join sbct_acquisti.order_status o on(o.id = c.order_status)
    where c.budget_id=#{self.id} group by s.supplier_id,s.supplier_name,o.label order by s.supplier_name,o.label;}
    puts sql
    SbctSupplier.find_by_sql(sql)
  end

  def assegna_fornitori(supplier_ids)
    if !self.supplier_id.nil?
      # puts "Non assegno fornitori perché questo budget ha un fornitore associato: #{self.supplier_id}"
      return
    end
    puts "Assegno fornitori #{supplier_ids} alle copie con order_status 'P' del budget #{self.to_label}"
    # puts self.total_amount

    quota_fornitore = SbctSupplier.quota_fornitore('MiC22', 'MiC 2022')
    puts "Importo massimo per fornitore: #{quota_fornitore}"
    
    sql=%Q{select sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata 
          from sbct_acquisti.copie where budget_id = #{self.id} and supplier_id is not null and order_status ='P' and prezzo notnull;}
    cifra_impegnata = self.connection.execute(sql).to_a.first['cifra_impegnata'].to_f
    puts "Cifra impegnata: #{cifra_impegnata}"

    sql = %Q{select supplier_id,sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata
          from sbct_acquisti.copie where supplier_id in(#{supplier_ids.join(',')}) and order_status ='P' and prezzo notnull group by supplier_id;}
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
          and order_status ='P' and prezzo notnull and prezzo < 100 ORDER BY prezzo;}
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

  def associa_a_lista(sbct_list)
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
      bib = clavis_budget.clavis_library.shortlabel.strip
      label << " - #{bib}" if !label.match(bib).to_s
    end
    label
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
    }
    self.connection.execute(sql)
  end

  def SbctBudget.associa_biblioteche(budgets)
    budgets.each do |r|
      next if r.library_id.nil?
      puts "budget per biblioteca #{r.library_id}: #{r.shortlabel} - #{r.total_amount}"
    end
    nil
  end

  def SbctBudget.tutti(params={})
    where = params[:budget_id].blank? ? "b.budget_id>0" : "b.budget_id=#{params[:budget_id]}"
    cond = []
    cond << "b.label ~ #{SbctBudget.connection.quote(params[:label])}" if !params[:label].blank?
    cond << "cb.budget_title = #{SbctBudget.connection.quote(params[:budget_label])}" if !params[:budget_label].blank?
    cond = cond.size==0 ? '' : "AND #{cond.join(' AND ')}"
    sql=%Q{
select b.label, b.budget_id, sum(c.numcopie) as numero_copie,
COALESCE((sum(c.prezzo * c.numcopie)),0) as impegnato,
to_char(avg(c.prezzo), 'FM999999999.00') as costo_medio,
b.total_amount,
b.total_amount - COALESCE((sum(c.prezzo * c.numcopie)),0) as residuo
FROM sbct_acquisti.budgets b JOIN clavis.budget cb on(cb.budget_id=b.clavis_budget_id) left join sbct_acquisti.copie c
on(c.budget_id=b.budget_id) left join sbct_acquisti.titoli t using(id_titolo)
WHERE #{where} #{cond} group by b.label,b.budget_id
order by b.label;
    }
    puts sql
    SbctBudget.find_by_sql(sql)
  end

  def SbctBudget.label_select()
    sql=%Q{select ab.budget_id as key,ab.label, ab.total_amount, trim(cl.shortlabel) as clavis_label
         from sbct_acquisti.budgets ab
           left join clavis.budget cb on (cb.budget_id=ab.clavis_budget_id) left join clavis.library cl using(library_id)
             where ab.label is not null order by ab.label;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = r['label']
      label << " (#{r['clavis_label']}, #{r['total_amount']} euro)" if !r['clavis_label'].nil?
      res << [label,r['key']]
    end
    res
  end

  def SbctBudget.loop_assegna_fornitori
    while SbctBudget.assegna_fornitori > 0 do
      SbctBudget.assegna_fornitori('asc')
    end
  end

  def SbctBudget.assegna_fornitori(order_by_prezzo='asc',budget_ids=[], supplier_ids=[])
    puts "Entro in SbctBudget.assegna_fornitori"
    #supplier_ids = SbctSupplier.where("supplier_name ~ '^MiC22' and supplier_id!=154").collect{|s| s.id}
    #sql = "UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE supplier_id in (#{supplier_ids.join(',')});"
    #puts sql
    #self.connection.execute(sql)

=begin
    supplier_ids = SbctSupplier.where("supplier_name ~ '^MiC22' and supplier_id!=154").collect{|s| s.id}
    SbctBudget.where("label ~ 'MiC 2022'").each do |b|
      puts "Assegno fornitori per budget #{b.id} : #{b.to_label}"
      b.assegna_fornitori(supplier_ids)
    end
    return
=end

    supplier_ids = SbctSupplier.where("supplier_name ~ '^MiC22'").collect{|s| s.id} if supplier_ids.size==0
    budget_ids = SbctBudget.where("label ~ '^MiC 2022'").collect{|s| s.id} if budget_ids.size==0

    
=begin
    sql = "UPDATE sbct_acquisti.copie SET order_date = NULL WHERE supplier_id in (#{supplier_ids.join(',')}) and budget_id in (#{budget_ids.join(',')});"
    puts sql
    self.connection.execute(sql)
    sql = "UPDATE sbct_acquisti.copie SET order_status = 'P' WHERE supplier_id in (#{supplier_ids.join(',')}) and order_status='O' and budget_id in (#{budget_ids.join(',')});"
    puts sql
    self.connection.execute(sql)
    sql = "UPDATE sbct_acquisti.copie SET supplier_id = NULL WHERE supplier_id in (#{supplier_ids.join(',')}) and budget_id in (#{budget_ids.join(',')});"
    puts sql
    self.connection.execute(sql)
=end

    quota_fornitore = SbctSupplier.quota_fornitore('MiC22', 'MiC 2022')
    puts "Importo massimo per fornitore: #{quota_fornitore}"

    sql = %Q{select supplier_id,sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata
          from sbct_acquisti.copie where supplier_id in(#{supplier_ids.join(',')}) 
          and order_status IN ('O','P')
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
    puts "numsuppliers: #{numsuppliers}"

    sql = %Q{select budget_id,sum(prezzo*numcopie)::numeric(10,2) as cifra_impegnata
          from sbct_acquisti.copie where budget_id in(#{budget_ids.join(',')})
           and order_status = 'O' and prezzo notnull group by budget_id;}
    puts sql
    hb=Hash.new
    self.connection.execute(sql).each do |r|
      hb[r['budget_id'].to_i] = r['cifra_impegnata'].to_f
    end
    # puts "Stato iniziale dei budgets: #{hb.inspect}"
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
    sql = %Q{
with multicopia as
(    
    select c.id_titolo,count(*) as numero_copie from sbct_acquisti.copie c
     join sbct_acquisti.titoli t using(id_titolo)
     where budget_id in (#{budget_ids.join(',')})
     and c.supplier_id is null and t.prezzo is not null
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
        puts "=> #{r['numero_copie']} copie per il titolo #{r['id_titolo']} con prezzo #{r['prezzo']}"
      end
      count_down -= 1
      # puts " => count_down: #{count_down} / i: #{i} / copia #{r['id_copia']} / prezzo: #{r['prezzo']} / fornitore #{supplier_ids[i]} / impegnato #{hs[supplier_ids[i]].round(2)} euro su #{quota_fornitore}"
      prezzo = r['prezzo'].to_f
      numcopie = r['numcopie'].to_i
      if (hs[supplier_ids[i]] + prezzo * numcopie) > quota_fornitore
        puts "NON ASSEGNO la copia #{r['id_copia']} - prezzo: #{prezzo} al fornitore #{supplier_ids[i]} che ha già impegnato #{hs[supplier_ids[i]].round(2)} euro su #{quota_fornitore}" if numcopie > 1
        next
      else
        budget_id = r['budget_id'].to_i
        if (hb[budget_id] + prezzo * numcopie) > ha[budget_id]
          # puts "Non assegno copia #{r['id_copia']} - prezzo: #{prezzo} al budget_id #{budget_id} : importo budget #{ha[budget_id]} (già assegnati #{hb[budget_id].round(2)} euro)"
        else
          s = "UPDATE sbct_acquisti.copie SET supplier_id=#{supplier_ids[i]} WHERE id_copia=#{r['id_copia']};"
          # puts s
          sqli << s
          hs[supplier_ids[i]] += prezzo * numcopie
          hb[budget_id] += prezzo * numcopie
          puts "i = #{i} supplier #{supplier_ids[i]} (importo: #{hs[supplier_ids[i]].round(2)}) - budget_id: #{budget_id} (importo: #{hb[budget_id].round(2)} su #{ha[budget_id]})"
          assegnate += 1
        end
      end
    end
    self.connection.execute(sqli.join("\n"))
    puts "Esco da assegna_fornitori - assegnate #{assegnate} copie"
    assegnate
  end

end
