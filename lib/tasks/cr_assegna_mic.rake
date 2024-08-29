# coding: utf-8
# -*- mode: ruby;-*-

desc 'Assegnazione ordini MiC 2022 a librerie'

def find_budgets
  SbctBudget.tutti(label:'MiC 2022')
end

def find_suppliers
  # SbctSupplier.find_by_sql "select * from sbct_acquisti.suppliers where supplier_name ~ '^Libr' and supplier_id!=154 order by random()"
  SbctSupplier.find_by_sql "select * from sbct_acquisti.suppliers where supplier_name ~ '^Libr' and supplier_id!=154 order by supplier_name;"
end

def effettua_assegnazioni(totale_da_spendere, budget_hash, suppliers_hash, suppliers_items_hash)
  puts "Entrato in effettua_assegnazioni"
  sql = %Q{
with multicopia as

(    
    select c.id_titolo,count(*) as numero_copie from sbct_acquisti.l_titoli_liste tl join sbct_acquisti.copie c on(c.id_titolo=tl.id_titolo)
     join sbct_acquisti.titoli t on(t.id_titolo=c.id_titolo)
     where tl.id_lista = (select id_lista from sbct_acquisti.liste where label = 'Acquisti MiC 2022')
     and c.supplier_id is null and t.prezzo is not null
         group by c.id_titolo
)
     select mc.numero_copie,t.prezzo as prezzo_titolo,c.* from sbct_acquisti.l_titoli_liste tl join sbct_acquisti.copie c on(c.id_titolo=tl.id_titolo)
       join sbct_acquisti.titoli t on(t.id_titolo=c.id_titolo)
       join multicopia mc on(mc.id_titolo=c.id_titolo)
       where tl.id_lista = (select id_lista from sbct_acquisti.liste where label = 'Acquisti MiC 2022')
       and c.supplier_id is null and t.prezzo is not null
       order by mc.numero_copie desc, t.id_titolo;
  }
  suppliers = find_suppliers
  numsuppliers = suppliers.size
  quota_per_fornitore = totale_da_spendere/numsuppliers
  puts "totale_da_spendere: #{totale_da_spendere} - per ognuno dei #{numsuppliers}: #{quota_per_fornitore}"

  supplier = nil
  totale_ordine = 0.0
  numcopie = 0
  SbctItem.find_by_sql(sql).each do |item|
    suppliers = find_suppliers if suppliers.count == 0
    (numcopie = item.numero_copie.to_i ; supplier = suppliers.shift) if numcopie == 0
    media = (s=0;suppliers_items_hash.each_value {|v| s+=v };s/numsuppliers)
    puts "Inizio loop (media: #{media}) - item #{item.id} - numero_copie: #{item.numero_copie} numcopie #{numcopie} fornitore #{supplier.id} - #{supplier.supplier_name}"
    numcopie += -1
    if budget_hash[item.budget_id].nil?
      puts "budget #{item.budget_id} non utilizzabile per la copia con id #{item.id}"
      next
    end
    # iteem.prezzo = item.prezzo_titolo
    newload = false
    while true
      if ( (suppliers_hash[supplier.id] + item.prezzo * item.numcopie) <= quota_per_fornitore )
        # puts "Esco dal ciclo while avendo come fornitore corrente #{supplier.id}"
        break
      end
      puts "Superata quota #{quota_per_fornitore} fornitore #{supplier.supplier_name} #{supplier.id} : #{suppliers_hash[supplier.id] + item.prezzo}"
      supplier = suppliers.shift
      if supplier.nil?
        puts "Esaurita lista fornitori, va ricaricata"
        if newload==false
          suppliers = find_suppliers
          newload = true
          puts "Ricarica fornitori: #{suppliers.size}"
          supplier = suppliers.shift
          next
        else
          puts "Fornitori esauriti, termino prematuramente l'assegnazione"
          break
        end
      end
      puts "Selezionato fornitore #{supplier.supplier_name} #{supplier.id} - impegnato #{suppliers_hash[supplier.id]} su max #{quota_per_fornitore}"
    end
    break if newload == true

    if (item.numero_copie.to_i == 1 and ((suppliers_items_hash[supplier.id]) > media+5))
      puts "NON assegno copia #{suppliers_items_hash[supplier.id] + 1} (media: #{media} - numcopie: #{numcopie} numero_copie: #{item.numero_copie}) al fornitore #{supplier.id} #{item.id} (parziale: #{suppliers_hash[supplier.id]})"
    else
      item.sbct_supplier = supplier
      suppliers_hash[supplier.id] += item.prezzo*item.numcopie
      suppliers_items_hash[supplier.id] += 1
      totale_ordine += item.prezzo * item.numcopie
      item.save!

      # vero_importo = SbctTitle.connection.execute("select sum(prezzo) from sbct_acquisti.copie where supplier_id = 230").to_a.first['sum'] if supplier.id==230
      # puts "Assegnata copia #{suppliers_items_hash[supplier.id]} (media: #{media} - numcopie: #{numcopie} numero_copie: #{item.numero_copie}) al fornitore #{item.supplier_id} -  #{supplier.id} (progressivo: #{suppliers_hash[supplier.id]}) e vero_importo: #{vero_importo}" if supplier.id==230
      break if totale_ordine >= totale_da_spendere
    end
  end
  puts "Esco da effettua_assegnazioni"
end

task :cr_assegna_mic => :environment do
  puts "Entro in cr_assegna_mic"

  sql=%Q{
      -- update sbct_acquisti.copie  set supplier_id = null where supplier_id notnull;
      -- update sbct_acquisti.copie set supplier_id = 154 where budget_id=1;
      -- update sbct_acquisti.copie as c set prezzo = t.prezzo - (cs.discount*t.prezzo)/100 from sbct_acquisti.titoli t join clavis.supplier cs on(cs.supplier_id=supplier_id) where c.id_titolo=t.id_titolo and c.supplier_id=154;
  }
  SbctTitle.connection.execute(sql)

  totale_da_spendere = 0.0
  budget_hash={}
  find_budgets.each do |r|
    impegno_reale = r.impegnato.to_f > r.total_amount.to_f ? r.total_amount.to_f : r.impegnato.to_f
    puts "r: #{r.to_label} - Impegno reale: #{impegno_reale} - Impegnato: #{r.impegnato.to_f}"
    budget_hash[r.id]=r; totale_da_spendere += impegno_reale
  end
  # totale_spesa = SbctTitle.connection.execute("select sum(total_amount) from sbct_acquisti.budgets where label ~ '^MiC 2022'").to_a.first['sum'].to_f
  suppliers = find_suppliers
  suppliers_hash = Hash.new
  suppliers_items_hash = Hash.new
  suppliers.collect {|r| suppliers_hash[r.supplier_id] = 0.0}
  suppliers.collect {|r| suppliers_items_hash[r.supplier_id] = 0}
  effettua_assegnazioni(totale_da_spendere, budget_hash, suppliers_hash, suppliers_items_hash)
  # fettua_assegnazioni(totale_da_spendere, budget_hash, suppliers_hash, suppliers_items_hash)

  ActiveRecord::Base.connection.execute("update sbct_acquisti.copie set order_status = 'P' where order_status is null and budget_id is not null and supplier_id is not null")
  
  puts "Fine assegnazioni"
end
