# coding: utf-8
module SbctOrdersHelper

  def sbct_orders_index(sbct_orders)
    res = []
    res << content_tag(:tr, content_tag(:td, 'OrderId', class:'col-md-1') +
                            content_tag(:td, 'OrderDate', class:'col-md-2 text-left') +
                            content_tag(:td, 'Inviato', class:'col-md-1 text-left') +
                            content_tag(:td, 'Fornitore', class:'col-md-2 text-left') +
                            content_tag(:td, 'Descrizione', class:'col-md-4 text-left') +
                            content_tag(:td, 'Numero copie', class:'col-md-1 text-left') +
                            content_tag(:td, 'Totale ordine', class:'col-md-2 text-left'), class:'success')
    sbct_orders.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.order_id, sbct_order_path(r), class:'btn btn-success')) +
                              content_tag(:td, r.order_date.to_date) +
                              content_tag(:td, (r.inviato? ? 'SI' : 'NO' )) +
                              content_tag(:td, link_to(r.supplier_name, sbct_supplier_path(r.supplier_id))) +
                              content_tag(:td, r.label) +
                              content_tag(:td, r.numero_copie) +
                              content_tag(:td, r.totale_ordine))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_order_show(sbct_order, sbct_items)
    res=[]
    if sbct_order.id.nil?
      lnk = link_to('Titolo', orders_report_sbct_supplier_path(sbct_order.supplier_id, group_by:'title', arrivati_o_ordinati:true), class:'btn btn-warning')
      lnk_stato_ordine = 'StatoOrdine'
      lnk_biblioteca = 'Biblioteca'
    else
      lnk = link_to('Titolo', sbct_order_path(sbct_order, group_by:'title'), class:'btn btn-success')
      lnk_stato_ordine = link_to('StatoOrdine', sbct_order_path(@sbct_order,order_by:'order_status'))
      lnk_biblioteca = link_to('Biblioteca', sbct_order_path(@sbct_order,order_by:'library'))
    end

    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, lnk, class:'col-md-3') +
                            content_tag(:td, 'id_copia', class:'col-md-1') +
                            content_tag(:td, 'prezzo scontato', class:'col-md-1') +
                            content_tag(:td, 'numcopie', class:'col-md-1') +
                            content_tag(:td, 'Budget', class:'col-md-1') +
                            content_tag(:td, lnk_stato_ordine, class:'col-md-1') +
                            content_tag(:td, lnk_biblioteca, class:'col-md-2'), class:'success')
    cnt = 0
    if sbct_order.id.nil?
      sbct_items.each do |r|
        cnt+=1; res << sbct_order_show_row(r,cnt,nil)
      end
    else
      if can? :update_order_status, SbctItem
        sbct_items.each do |r|
          cnt+=1
          if r.order_status=='N' or !sbct_order.inviato?
            st_opt = nil
          else
            st_opt = options_for_select(SbctOrderStatus.options_for_select(['A','N','O']), r.order_status)
          end
          # res << sbct_order_show_row(r,cnt,options_for_select(SbctOrderStatus.options_for_select(['A','N','O']), r.order_status))
          res << sbct_order_show_row(r,cnt,st_opt)
        end
      else
        sbct_items.each do |r|
          cnt+=1; res << sbct_order_show_row(r,cnt,nil)
        end
      end
    end
    cnt == 0 ? 'Per questo ordine non ci sono (ancora) titoli caricati' : content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_order_show_row(r,cnt,status_options)
    budget_lnk = link_to(r.budget_id, sbct_budget_path(r.budget_id), class:'btn btn-warning', target:'_budgets')
    #trclass = 'warning' if r.order_status == 'N'

    if r.order_status.blank?
      orderstatus = r.order_status
      raise "uhm... r.order_status = #{r.order_status} per r.id #{r.id}"
    else
      if !status_options.nil?
        if r.data_arrivo.nil? or (r.data_arrivo == Time.now.to_date)
          orderstatus = select_tag(:order_status, status_options, line_counter:cnt, contesto:'ordine',onchange:"change_item_order_status(this,#{r.id})")
        else
          orderstatus = "#{r.order_status}<br/>".html_safe
        end
        edit_lnk = link_to(r.id, edit_sbct_item_path(r), class:'btn btn-warning', target:'_item')
      else
        orderstatus = "#{r.order_status}<br/>".html_safe
        edit_lnk = r.id
      end
    end
    if !r.data_arrivo.blank?
      if r.in_ritardo=='t'
        orderstatus << content_tag(:i, "Data arrivo: #{r.data_arrivo}", title:"Tempo impiegato: #{r.order_age}")
      else
        orderstatus << content_tag(:span, "Data arrivo: #{r.data_arrivo}", title:"Tempo impiegato: #{r.order_age}")
      end
    end
    h={A:'warning',N:'danger',O:'info'}
    trclass = h[r.order_status.to_sym]

    content_tag(:tr, content_tag(:td, cnt) +
                     content_tag(:td, link_to(r.titolo,sbct_title_path(r.id_titolo), target:'_blank')) +
                     content_tag(:td, edit_lnk) +
                     content_tag(:td, r.prezzo_scontato) +
                     content_tag(:td, r.numcopie) +
                     content_tag(:td, budget_lnk) +
                     content_tag(:td, orderstatus) +
                     content_tag(:td, r.siglabiblioteca), id:"sbct_item_#{r.id}", class:trclass)
  end

  def sbct_order_show_group_by_title(sbct_order, sbct_items)
    res=[]
    if sbct_order.id.nil?
      lnk = link_to('Titolo', orders_report_sbct_supplier_path(sbct_order.supplier_id, arrivati_o_ordinati:true), class:'btn btn-warning')
    else
      lnk = link_to('Titolo', sbct_order_path(sbct_order), class:'btn btn-success')
    end
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'EAN', class:'col-md-1') +
                            content_tag(:td, 'Autore', class:'col-md-2') +
                            content_tag(:td, lnk, class:'col-md-4') +
                            content_tag(:td, 'Editore', class:'col-md-2') +
                            content_tag(:td, 'Copie', class:'col-md-1') +
                            content_tag(:td, 'Prezzo', class:'col-md-1') +
                            content_tag(:td, 'Totale', class:'col-md-1') +
                            content_tag(:td, 'Biblioteche', class:'col-md-4'),class:'success')
    cnt = 0
    sbct_items.each do |r|
      cnt += 1; res << sbct_order_show_group_by_title_row(r,cnt)
    end
    cnt == 0 ? 'Per questo ordine non ci sono (ancora) titoli caricati' : content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_orders_check_dup
    res=[]
    res << content_tag(:thead, "Titoli duplicati da fondere")
    res << content_tag(:tr, content_tag(:td, 'EAN', class:'col-md-1') +
                            content_tag(:td, 'Titolo', class:'col-md-3') +
                            content_tag(:td, 'IdOrdine', class:'col-md-1'), class:'success')

    cnt = 0
    SbctOrder.trova_titoli_duplicati.each do |r|
      cnt += 1
      lnk = link_to(r.ean, sbct_titles_path("sbct_title[ean]":r.ean),target:'_fusione')
      res << content_tag(:tr, content_tag(:td, "#{cnt}. #{lnk}".html_safe) +
                              content_tag(:td, r.titolo) +
                              content_tag(:td, r.order_id))
    end

    cnt == 0 ? 'Nessun titolo duplicato' : content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')

  end

  def sbct_order_show_group_by_title_row(r,cnt)
    if r.note_fornitore.blank?
      sigle_e_note = r.siglebct
    else
      sigle_e_note = "#{r.siglebct}<br/><em>#{r.note_fornitore}</em>".html_safe
    end
    content_tag(:tr, content_tag(:td, cnt) +
                     content_tag(:td, r.ean) +
                     content_tag(:td, r.autore) +
                     content_tag(:td, link_to(r.titolo, sbct_title_path(r.id_titolo), target:'_blank')) +
                     content_tag(:td, r.editore) +
                     content_tag(:td, r.numcopie) +
                     content_tag(:td, number_to_currency(r.prezzo_scontato)) +
                     content_tag(:td, number_to_currency(r.prezzo_scontato.to_f*r.numcopie)) +
                     content_tag(:td, sigle_e_note))
  end

  def sbct_order_importi_disponibili(sbct_order,copie)
    "Dico qualcosa sull'ordine #{sbct_order.to_label} e budget #{sbct_order.sbct_budget.to_label} per le copie #{copie.inspect}"
    library_ids = copie.collect {|c| c.library_id}
    res=[]
    sbct_order.sbct_budget.snapshot(library_ids).each_pair do |k,v|
      sigla,qb=k
      label = qb==false ? "<b>#{sigla}</b> - Quota Ufficio acquisti" : "<b>#{sigla}</b> - Quota biblioteca"
      res << content_tag(:tr, content_tag(:td, label.html_safe, class:'col-md-4') +
                              content_tag(:td, "#{number_to_currency(v)}"))
    end
    # sbct_budget_items(sbct_order.sbct_budget,library_ids)
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

end
