# coding: utf-8
class SbctInvoice < ActiveRecord::Base
  self.table_name='sbct_acquisti.invoices'
  attr_accessible :label, :invoice_date, :total_amount, :clavis_invoice_id, :notes, :rounding
  before_save :check_record

  has_many :sbct_invoice_items, foreign_key:'invoice_id'
  has_many :sbct_items, foreign_key:'invoice_id'
  belongs_to :sbct_supplier, foreign_key:'supplier_id'
  belongs_to :clavis_library, foreign_key:'library_id'

  def to_label
    # self.label.blank? ? "Fattura per biblioteca #{clavis_library.siglabct} #{self.sbct_supplier.supplier_name}": self.label
    self.label.blank? ? "Fattura per biblioteca #{clavis_library.siglabct}": self.label
  end

  def check_record
    self.attribute_names.each do |f|
      self.assign_attributes(f=>nil) if self.send(f).blank?
    end
  end

  # Documenti di trasporto relavtivi a questa fattura NON USATA NON USARE
  def documenti_di_trasporto
    sql = %Q{
          select invoice_id,tipo_documento,ddt_date,ddt_numero,count(*) as num_titoli
        from sbct_acquisti.invoice_items where invoice_id = #{self.id}
      group by invoice_id,tipo_documento,ddt_date,ddt_numero order by ddt_date;}
      SbctInvoiceItem.connection.execute(sql).to_a
  end

  def SbctInvoice.tutte_old(params={})
      sql=%Q{select i.invoice_id,i.label,count(*) as num_titoli,
            array_to_string(array_agg(distinct ii.ddt_numero),', ') as ddt,
            sum(valore_unitario*quantita) as importo_totale,sum(netto*quantita) as netto
       from sbct_acquisti.invoices i join sbct_acquisti.invoice_items ii using(invoice_id)
       group by i.invoice_id,i.label order by label desc;
      }

      puts sql
      SbctInvoice.find_by_sql(sql)
  end

  # Esempio:
  #            SbctInvoice.roundings('^MiC',difetto=true)
  #
  def SbctInvoice.roundings(pattern,difetto=true)
    quota = SbctSupplier.quota_fornitore(pattern, pattern, difetto=difetto)
    self.connection.execute %Q{update sbct_acquisti.invoices set rounding=0 where rounding > 0;
          update sbct_acquisti.copie set invoice_id=NULL where invoice_id notnull and order_status not in ('A','O');
          update sbct_acquisti.copie as c set invoice_id=i.invoice_id from sbct_acquisti.invoices i where i.supplier_id=c.supplier_id 
               and i.library_id = c.library_id
               and c.order_status IN ('A','O') and c.invoice_id is null;}

    sql = %Q{with t1 as
(
select cb.library_id,b.total_amount,sum(cp.prezzo*cp.numcopie) as speso
  from sbct_acquisti.budgets b join clavis.budget cb on (cb.budget_id=b.clavis_budget_id)
   join sbct_acquisti.copie cp on(cp.budget_id=b.budget_id)
    where b.label ~ '#{pattern}' and cb.library_id > 1 and cp.order_status IN ('A','O')
      group by cb.library_id,b.total_amount
)
  select t1.library_id,cl.shortlabel as library,total_amount,t1.speso,total_amount-speso as da_spendere
   from t1 join clavis.library cl using(library_id)
      where total_amount-speso > 0 order by da_spendere}

    # puts sql

    debito = Hash.new
    self.connection.execute(sql).to_a.each do |r|
      debito[r['library_id'].to_i] = r['da_spendere'].to_f
    end
    puts debito.inspect
    a = 1
    
    sql = %Q{
         with t1 as
       (select s.supplier_id,sum(cp.prezzo*cp.numcopie) as fornito
         from sbct_acquisti.suppliers s join sbct_acquisti.copie cp on(cp.supplier_id=s.supplier_id)
         where cp.order_status IN ('A','O') and s.supplier_name~'#{pattern}'
         group by s.supplier_id)
       select t1.supplier_id,t1.fornito,#{quota}-t1.fornito as credito from t1
       where #{quota}-t1.fornito > 0 order by credito desc,t1.supplier_id
       }
    puts sql
    credito = Hash.new
    self.connection.execute(sql).to_a.each do |r|
      # puts r.inspect
      credito[r['supplier_id'].to_i] = r['credito'].to_f
    end
    puts credito.inspect
    exec_sql = []
    # Ora vado a vedere le fatture che deve emettere ogni fornitore:
    credito.keys.each do |k|
      puts "\nEsamino fatture del fornitore #{k} che ha un credito di #{credito[k]}"
      invoices = SbctInvoice.where(supplier_id:k)
      invoices.each do |i|
        next if debito[i.library_id].nil?
        puts "fattura #{i.invoice_id} per biblioteca #{i.library_id} che ha un debito di #{debito[i.library_id]} - credito del fornitore #{credito[k]}"
        if credito[k] > debito[i.library_id]
          rnd = (credito[k] - debito[i.library_id]).round(2)
          rnd = debito[i.library_id] if rnd > debito[i.library_id]
        else
          rnd = credito[k]
        end
        credito[k] = (credito[k]-rnd).round(2)
        debito[i.library_id] = (debito[i.library_id]-rnd).round(2)
        sq = "UPDATE sbct_acquisti.invoices SET rounding=#{rnd} WHERE invoice_id=#{i.invoice_id};"
        puts sq
        self.connection.execute(sq)
        exec_sql << sq
        puts "  >> credito portato a #{credito[k]} (debito della biblioteca #{i.library_id} diventa #{debito[i.library_id]})"
        debito[i.library_id] = nil if debito[i.library_id]==0
        break if credito[k]==0
      end
      if credito[k]>0
        # Questa situazione rappresenta una condizione di errore, ma non conviene uscire con "raise" a meno di non catchare l'errore dalla chiamante
        puts "  --------> dopo il break: credito #{credito[k]}"
        # raise "  --------> dopo il break: credito #{credito[k]}"
      end
    end
    # self.connection.execute(exec_sql.join)
  end

  def SbctInvoice.tutte(params={})
    cond = []
    cond << "i.supplier_id = #{self.connection.quote(params[:supplier_id])}" if !params[:supplier_id].blank?
    cond << "i.library_id = #{self.connection.quote(params[:library_id])}" if !params[:library_id].blank?
    cond << "s.supplier_name ~ #{self.connection.quote(params[:supplier_label])}" if !params[:supplier_label].blank?
    cond = cond.size==0 ? '' : "AND #{cond.join(' AND ')}"
    sql=%Q{
select s.supplier_name as fornitore,lc.label as siglabib,cl.shortlabel as biblioteca,i.invoice_id,
     i.invoice_date, i.supplier_id,i.library_id,
      sum(cp.numcopie) as numcopie, sum(cp.prezzo*cp.numcopie) as importo_fattura,
      i.rounding, sum(cp.prezzo*cp.numcopie) + i.rounding as importo_totale
 from sbct_acquisti.invoices i
   join sbct_acquisti.library_codes lc on (lc.clavis_library_id = i.library_id)
   join clavis.library cl on (cl.library_id=lc.clavis_library_id)
   join clavis.budget cb on (cb.library_id=i.library_id)
   join sbct_acquisti.budgets b on (b.clavis_budget_id=cb.budget_id)
   join sbct_acquisti.suppliers s on (s.supplier_id=i.supplier_id)
   join sbct_acquisti.copie cp on(cp.budget_id=b.budget_id
   			          and cp.library_id=i.library_id
				  and cp.supplier_id=i.supplier_id)
   where cb.library_id > 1 and cp.order_status IN ('A','O') #{cond}
    group by fornitore,siglabib,biblioteca,i.invoice_id order by fornitore,siglabib
}
    puts sql
    SbctInvoice.find_by_sql(sql)
  end

  def SbctInvoice.read_from_file(filename)
    d = File.open(filename, 'r') do |io|
      REXML::Document.new(io)
    end
    root = d.root
    headers = root.elements["FatturaElettronicaHeader"]
    puts headers
    vat_code = headers.elements["CedentePrestatore/DatiAnagrafici/IdFiscaleIVA/IdPaese"].text + headers.elements["CedentePrestatore/DatiAnagrafici/IdFiscaleIVA/IdCodice"].text
    puts "vat_code: #{vat_code}"
    clavis_supplier = ClavisSupplier.find_by_vat_code(vat_code)
    puts "clavis_supplier: #{clavis_supplier.id}"
    body = root.elements["FatturaElettronicaBody"]
    dati_generali = body.elements["DatiGenerali"]
    puts dati_generali
    invoice_number = dati_generali.elements["DatiGeneraliDocumento/Numero"].text
    invoice_date = dati_generali.elements["DatiGeneraliDocumento/Data"].text
    puts invoice_number
    clavis_invoice = ClavisInvoice.find_by_supplier_id_and_invoice_number_and_invoice_date(clavis_supplier.id,invoice_number,invoice_date)
    puts clavis_invoice.inspect
    sbct_invoice = SbctInvoice.find_or_create_by_clavis_invoice_id(clavis_invoice.id)
    sbct_invoice.label = invoice_number
    sbct_invoice.save
    puts sbct_invoice.inspect
    nil
  end
end
