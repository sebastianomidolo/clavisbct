# coding: utf-8
module SbctInvoicesHelper

  def sbct_invoices_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Fornitore') +
                            content_tag(:td, 'Data') +
                            content_tag(:td, 'Numero fattura') +
                            content_tag(:td, 'Numero titoli') +
                            content_tag(:td, 'Importo totale') +
                            content_tag(:td, 'Scontato'))
    records.each do |r|
      lnk = link_to("#{r.label}<br/>DDT: #{r.ddt}".html_safe, sbct_invoice_path(r))
      res << content_tag(:tr, content_tag(:td, 'Leggere') +
                              content_tag(:td, 'non ho questo dato') +
                              content_tag(:td, lnk) +
                              content_tag(:td, r.num_titoli) +
                              content_tag(:td, number_to_currency(r.importo_totale)) +
                              content_tag(:td, number_to_currency(r.netto)))
    end

    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sbct_invoices_ddt(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Tipo documento', class:'col-md-2') +
                            content_tag(:td, 'Data', class:'col-md-1') +
                            content_tag(:td, 'Numero bolla', class:'col-md-2') +
                            content_tag(:td, 'Numero titoli', class:'col-md-8'))
    records.each do |r|
      lnk = link_to("#{r['ddt_date'].to_date}".html_safe, sbct_invoice_path(r['invoice_id'],ddt_numero:r['ddt_numero']))
      res << content_tag(:tr, content_tag(:td, r['tipo_documento']) +
                              content_tag(:td, lnk) +
                              content_tag(:td, r['ddt_numero']) +
                              content_tag(:td, r['num_titoli']))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')    
  end

  def sbct_invoice_items_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Autore', class:'col-md-2') +
                            content_tag(:td, 'Titolo', class:'col-md-2') +
                            content_tag(:td, 'Editore', class:'col-md-2') +
                            content_tag(:td, 'Prezzo copertina', class:'col-md-1') +
                            content_tag(:td, 'Prezzo netto', class:'col-md-1') +
                            content_tag(:td, 'Quantità', class:'col-md-1') +
                            content_tag(:td, 'Data ordine', class:'col-md-2'), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r.autore) +
                              content_tag(:td, r.titolo) +
                              content_tag(:td, r.editore) +
                              content_tag(:td, number_to_currency(r.valore_unitario)) +
                              content_tag(:td, number_to_currency(r.netto)) +
                              content_tag(:td, r.quantita) +
                              content_tag(:td, r.data_prenotazione.to_date))
    end

    content_tag(:table, res.join.html_safe, class:'table table-striped')    
  end
end
