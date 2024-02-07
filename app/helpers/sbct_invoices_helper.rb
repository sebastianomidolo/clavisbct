# coding: utf-8
module SbctInvoicesHelper

  def sbct_invoices_list_old(records)
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

  def sbct_invoices_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, '') +
                            content_tag(:td, 'Fornitore') +
                            content_tag(:td, 'Biblioteca') +
                            content_tag(:td, 'Data fattura') +
                            content_tag(:td, 'Numero copie') +
                            content_tag(:td, 'Importo') +
                            content_tag(:td, 'Arrotondamento') +
                            content_tag(:td, 'Importo totale'))
    cnt = 0
    nprog = 0
    sumrnd = 0.0
    totale = 0.0
    if !@sbct_supplier.nil?
      @supplier_label = @sbct_supplier.supplier_name.split.first
    end
    records.each do |r|
      cnt += r.numcopie.to_i
      nprog += 1
      sumrnd += r.rounding
      totale += r.importo_totale.to_f

      invoice_date = r.invoice_date.nil? ? '-' : r.invoice_date.to_date
      lnk = link_to("#{nprog}".html_safe, sbct_invoice_path(r.invoice_id), class:'btn btn-warning')
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, link_to(r.fornitore,sbct_invoices_path(supplier_id:r.supplier_id))) +
                              content_tag(:td, link_to("#{r.siglabib} - #{r.biblioteca}",sbct_invoices_path(library_id:r.library_id,supplier_label:@supplier_label))) +
                              content_tag(:td, invoice_date) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, r.importo_fattura) +
                              content_tag(:td, number_to_currency(r.rounding)) +
                              content_tag(:td, number_to_currency(r.importo_totale)))
    end
    res << content_tag(:tr, content_tag(:td, '') + content_tag(:td, '') +
                            content_tag(:td, '') +
                            content_tag(:td, '') +
                            content_tag(:td, cnt) +
                            content_tag(:td, '') +
                            content_tag(:td, number_to_currency(sumrnd)) +
                            content_tag(:td, number_to_currency(totale)))

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

  def sbct_invoice_items_list(sbct_items)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'EAN', class:'col-md-1') +
                            content_tag(:td, 'Autore', class:'col-md-2') +
                            content_tag(:td, 'Titolo', class:'col-md-4') +
                            content_tag(:td, 'Editore', class:'col-md-2') +
                            content_tag(:td, 'Copie', class:'col-md-1') +
                            content_tag(:td, 'Prezzo', class:'col-md-1') +
                            content_tag(:td, 'Totale', class:'col-md-1'),class:'success')
    cnt = 0
    prezzo = totale = 0
    sbct_items.each do |r|
      prezzo += r.prezzo_scontato.to_f
      totale += r.prezzo_scontato.to_f * r.numcopie
      cnt += 1; res << sbct_invoice_items_list_row(r,cnt)
    end
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, '', class:'col-md-2') +
                            content_tag(:td, '', class:'col-md-4') +
                            content_tag(:td, '', class:'col-md-2') +
                            content_tag(:td, cnt, class:'col-md-1') +
                            content_tag(:td, number_to_currency(prezzo), class:'col-md-1') +
                            content_tag(:td, number_to_currency(totale), class:'col-md-1'),class:'success')

    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_invoice_items_list_row(r,cnt)
    if can? :show, SbctTitle
      lnk = link_to(r.titolo, sbct_title_path(r.id_titolo), target:'_blank')
    else
      lnk = r.titolo
    end
    content_tag(:tr, content_tag(:td, r.ean) +
                     content_tag(:td, r.autore) +
                     content_tag(:td, lnk) +
                     content_tag(:td, r.editore) +
                     content_tag(:td, r.numcopie) +
                     content_tag(:td, number_to_currency(r.prezzo_scontato)) +
                     content_tag(:td, number_to_currency(r.prezzo_scontato.to_f*r.numcopie)) +
                     content_tag(:td, r.note_fornitore))
  end

end
