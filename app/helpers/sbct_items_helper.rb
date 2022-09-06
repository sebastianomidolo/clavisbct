# coding: utf-8
module SbctItemsHelper

  def sbct_items_list(records)
    res=[]
    lnk = params[:supplier_id].blank? ? 'Titolo' : link_to('Titolo', orders_sbct_items_path(group_by:'title',order_date:params[:order_date],supplier_id:params[:supplier_id]))
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, lnk, class:'col-md-3') +
                            content_tag(:td, 'id_copia', class:'col-md-1') +
                            content_tag(:td, 'prezzo scontato', class:'col-md-1') +
                            content_tag(:td, 'numcopie', class:'col-md-1') +
                            content_tag(:td, 'budget', class:'col-md-1') +
                            content_tag(:td, 'StatoOrdine', class:'col-md-1') +
                            content_tag(:td, 'fornitore', class:'col-md-1') +
                            content_tag(:td, 'biblioteca', class:'col-md-2'), class:'success')

    cnt = 0
    # content_tag(:td, link_to(r.titolo,sbct_items_path("sbct_item[id_titolo]":r.id_titolo), target:'_blank')) +

    # content_tag(:td, link_to(r.supplier_id, sbct_supplier_path(r.supplier_id), class:'btn btn-warning', target:'_suppliers')) +
    records.each do |r|
      cnt += 1
      lnk = r.supplier_id.nil? ? '' : link_to(r.supplier_id, sbct_supplier_path(r.supplier_id), class:'btn btn-warning', target:'_suppliers')

      budget_lnk = r.budget_id.nil? ? '' : link_to(r.budget_id, sbct_budget_path(r.budget_id), class:'btn btn-warning', target:'_budgets')
      res << content_tag(:tr, content_tag(:td, cnt) +
                              content_tag(:td, link_to(r.titolo,sbct_title_path(r.id_titolo), target:'_blank')) +
                              content_tag(:td, link_to(r.id, edit_sbct_item_path(r), target:'_blank')) +
                              content_tag(:td, r.prezzo_scontato) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, budget_lnk) +
                              content_tag(:td, r.order_status) +
                              content_tag(:td, lnk) +
                              content_tag(:td, r.siglabiblioteca))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_items_list_group_by_title(records)
    res=[]
    cnt = 0
    lnk = link_to('Biblioteche', orders_sbct_items_path(group_by:'title',format:'csv', order_date:params[:order_date],supplier_id:params[:supplier_id]))

    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'EAN', class:'col-md-1') +
                            content_tag(:td, 'Autore', class:'col-md-2') +
                            content_tag(:td, link_to('Titolo', orders_sbct_items_path(order_date:params[:order_date],supplier_id:params[:supplier_id])), class:'col-md-4') +
                            content_tag(:td, 'Editore', class:'col-md-2') +
                            content_tag(:td, 'Copie', class:'col-md-1') +
                            content_tag(:td, 'Prezzo', class:'col-md-1') +
                            content_tag(:td, 'Totale', class:'col-md-1') +
                            content_tag(:td, lnk, class:'col-md-4'),class:'success')

    records.each do |r|
      cnt += 1
      res << content_tag(:tr, content_tag(:td, cnt) +
                              content_tag(:td, r.ean) +
                              content_tag(:td, r.autore) +
                              content_tag(:td, link_to(r.titolo, sbct_title_path(r.id_titolo), target:'_blank')) +
                              content_tag(:td, r.editore) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, number_to_currency(r.prezzo)) +
                              content_tag(:td, number_to_currency(r.prezzo*r.numcopie)) +
                              content_tag(:td, r.siglebct))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end


  
  def sbct_items_order_list(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'id_copia', class:'col-md-1') +
                            content_tag(:td, 'titolo', class:'col-md-5') +
                            content_tag(:td, 'costo', class:'col-md-1') +
                            content_tag(:td, 'numcopie', class:'col-md-1') +
                            content_tag(:td, 'budget', class:'col-md-1') +
                            content_tag(:td, 'StatoOrdine', class:'col-md-1') +
                            content_tag(:td, 'fornitore', class:'col-md-1') +
                            content_tag(:td, 'biblioteca', class:'col-md-1'), class:'success')

    records.each do |r|
      res << content_tag(:tr, content_tag(:td, check_box_tag("item_ids[]", r.id_copia, true)) +
                              content_tag(:td, link_to(r.id, edit_sbct_item_path(r), target:'_blank')) +
                              content_tag(:td, link_to(r.titolo, sbct_title_path(r.id_titolo), target:'_blank')) +
                              content_tag(:td, r.prezzo) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, r.budget_id) +
                              content_tag(:td, r.order_status) +
                              content_tag(:td, r.supplier_id) +
                              content_tag(:td, r.siglabiblioteca))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_item_orders_index(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Data ordine', class:'col-md-2') +
                            content_tag(:td, 'Fornitore', class:'col-md-4') +
                            content_tag(:td, 'Numero copie', class:'col-md-2') +
                            content_tag(:td, '', class:'col-md-1'), class:'success')
    records.each do |r|
      order_date = r['order_date'].blank? ? '(senza data)' : r['order_date'].to_date
      order_date_lnk = r['order_date'].blank? ? 'NULL' : r['order_date']
      lnk = link_to(order_date, orders_sbct_items_path(order_date:order_date_lnk,supplier_id:r['supplier_id']))
      download_csv = records.size == 1 ? link_to('Scarica CSV', orders_sbct_items_path(group_by:'title',format:'csv', order_date:params[:order_date],supplier_id:params[:supplier_id]), class:'btn btn-warning') : ''
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, link_to(r['supplier_name'], orders_sbct_items_path(supplier_id:r['supplier_id']))) +
                              content_tag(:td, r['numcopie']) +
                              content_tag(:td, download_csv))


                              
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  
end
