# coding: utf-8
class SbctInvoice < ActiveRecord::Base
  self.table_name='sbct_acquisti.invoices'
    attr_accessible :label
    has_many :sbct_invoice_items, foreign_key:'invoice_id'

    def to_label
      self.label
    end

    # Documenti di trasporto relavtivi a questa fattura
    def documenti_di_trasporto
      sql = %Q{
          select invoice_id,tipo_documento,ddt_date,ddt_numero,count(*) as num_titoli
        from sbct_acquisti.invoice_items where invoice_id = #{self.id}
      group by invoice_id,tipo_documento,ddt_date,ddt_numero order by ddt_date;}
      SbctInvoiceItem.connection.execute(sql).to_a
    end

    def SbctInvoice.tutte(params={})
      sql=%Q{select i.invoice_id,i.label,count(*) as num_titoli,
            array_to_string(array_agg(distinct ii.ddt_numero),', ') as ddt,
            sum(valore_unitario*quantita) as importo_totale,sum(netto*quantita) as netto
       from sbct_acquisti.invoices i join sbct_acquisti.invoice_items ii using(invoice_id)
       group by i.invoice_id,i.label order by label desc;
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
                                       
      #  d.elements.each('FatturaElettronicaHeader') do |e|
      #  puts e.inspect
      #end
    end
end
