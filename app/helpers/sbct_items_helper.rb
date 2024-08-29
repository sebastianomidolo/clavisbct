# coding: utf-8
module SbctItemsHelper

  def sbct_items_per_libraries(params,heading='')
    if params.class == Hash
      id_lista = params[:id_lista].blank? ? nil : params[:id_lista].to_i
    end
    if current_user.email=='seba'
      # return params.inspect
    end
    records = SbctItem.items_per_libraries(params)

    res=[]
    totale=0.0
    ncopie=0
    res << content_tag(:tr, content_tag(:td, 'Sigla', class:'col-md-1') +
                            content_tag(:td, 'Quota', class:'col-md-1') +
                            content_tag(:td, 'Importo', class:'col-md-1') +
                            content_tag(:td, 'SubQuota', class:'col-md-1') +
                            content_tag(:td, 'Assegnati', class:'col-md-1') +
                            content_tag(:td, 'Spesi', class:'col-md-1') +
                            content_tag(:td, 'Percent spesi', class:'col-md-1') +
                            content_tag(:td, 'Numero copie', class:'col-md-1') +
                            content_tag(:td, 'Disponibili', class:'col-md-1'), class:'success')

    all = []
    prec_line = {}
    qb_ok = false
    prec_sigla = ''
    records.each do |r|
      if prec_sigla != r.siglabct and  prec_line!={}
        #prec_line.quota=0 if prec_line.qb.blank?
        #all << prec_line
      end
      if prec_line != {} and r.qb==prec_line.qb
        prec_line.numero_copie=0
        prec_line.qb=true
        prec_line.subquota = 100 - prec_line.subquota.to_f
        prec_line.assegnati = prec_line.totale_assegnato.to_f - prec_line.assegnati.to_f
        prec_line.spesi = prec_line.spesi_percent = 0
        prec_line.ancora_disp = prec_line.assegnati
        all << prec_line
      end
      prec_line = r.dup
      prec_sigla = r.siglabct
      all << r.dup
    end
    if prec_line != {} and prec_line.qb == false
      prec_line.numero_copie=0
      prec_line.qb=true
      prec_line.subquota = 100 - prec_line.subquota.to_f
      prec_line.assegnati = prec_line.totale_assegnato.to_f - prec_line.assegnati.to_f
      prec_line.spesi = prec_line.spesi_percent = 0
      prec_line.ancora_disp = prec_line.assegnati
      all << prec_line
    end
    if current_user.email=='seba'
      # return "agisco su #{all}"
    end
    
    cnt = 0

    all.each do |r|
      cnt += 1
      ncopie += r.numero_copie.to_i
      totale += r.assegnati.to_f
      if params.class == Hash
        qb_select = r.qb.blank? ? '' : 'S'
        budget_id = params[:budget_ids].blank? ? '' : params[:budget_ids]

        if r.qb.blank?
          classe = 'success'
          row_title = "Scelti da Ufficio acquisti"
          quota = "#{r.quota}%"
          totale_assegnato = number_to_currency(r.totale_assegnato)
        else
          classe = 'info'
          row_title = "Scelti dalla biblioteca #{r.siglabct}"
          quota = totale_assegnato = '-'
        end
        biblioteca = %Q{#{link_to(r.siglabct, sbct_titles_path("sbct_title[clavis_library_ids]":r.library_id,id_lista:id_lista,supplier_id:params[:supplier_id],order_id:params[:order_id],budget_id:budget_id,order_status:params[:order_status],qb_select:qb_select,numcopie:params[:numcopie]), class:"btn btn-#{classe}")}}.html_safe
        # biblioteca = r.siglabct
      else
        biblioteca = r.biblioteca
      end

      subquota = r.subquota.blank? ? '' : "#{r.subquota}%"
      row_class = r.ancora_disp.to_f < 0 ? 'danger' : ''
      #if r.spesi_percent.to_f > r.quota_percent.to_f
      #  row_class = 'danger'
      #  specificazione = "<br/>(su #{r.quota_percent}%)"
      #else
#     #    specificazione = ""
      #  specificazione = "<br/>(su #{r.quota_percent}%)"
      #end

      disponibili = "<b>#{number_to_currency(r.ancora_disp)}</b>"
      disponibili = '-' if params[:contesto]=='ordine'
      res << content_tag(:tr, content_tag(:td, biblioteca) +
                              content_tag(:td, quota) +
                              content_tag(:td, totale_assegnato) +
                              content_tag(:td, subquota) +
                              content_tag(:td, number_to_currency(r.assegnati)) +
                              content_tag(:td, number_to_currency(r.spesi)) +
                              content_tag(:td, "#{r.spesi_percent}%".html_safe) +
                              content_tag(:td, r.numero_copie) +
                              content_tag(:td, disponibili.html_safe), class:row_class, title:row_title)

    end
    res << content_tag(:tr, content_tag(:td, 'a') +
                            content_tag(:td, 'b') +
                            content_tag(:td, 'c') +
                            content_tag(:td, 'd') +
                            content_tag(:td, 'e') +
                            content_tag(:td, 'f') +
                            content_tag(:td, 'g') +
                            content_tag(:td, 'h') +
                            content_tag(:td, 'i'))

    return '' if cnt==0
    "#{heading} #{content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')}".html_safe
  end

  def sbct_items_distribuzione_per_biblioteche(params,heading='')
    records = SbctItem.items_per_libraries(params)
    res=[]
    totale=0.0
    ncopie=0
    # res << content_tag(:tr, content_tag(:td, 'Sigla', class:'col-md-1') +
    #                         content_tag(:td, 'Numero copie', class:'col-md-1') +
    #                         content_tag(:td, 'Spesi', class:'col-md-1') +
    #                         content_tag(:td, 'Ancora disponibili', class:'col-md-2') +
    #                         content_tag(:td, 'Totale assegnato', class:'col-md-7'), class:'success')
    res << content_tag(:tr, content_tag(:td, 'Sigla', class:'col-md-1') +
                            content_tag(:td, 'Numero copie', class:'col-md-1') +
                            content_tag(:td, 'Spesi', class:'col-md-10'), class:'success')

    cnt = 0
    records.each do |r|
      cnt += 1
      ncopie += r.numero_copie.to_i
      totale += r.assegnati.to_f
      qb_select = r.qb.blank? ? 'N' : 'S'
      budget_id = params[:budget_ids].blank? ? '' : params[:budget_ids]
      if r.qb.blank?
        classe = 'success'
        row_title = "Scelti da Ufficio acquisti"
        totale_assegnato = number_to_currency(r.totale_assegnato)
      else
        classe = 'info'
        row_title = "Scelti dalla biblioteca #{r.siglabct}"
      end
      biblioteca = %Q{#{link_to(r.siglabct, sbct_titles_path("sbct_title[clavis_library_ids]":r.library_id,supplier_id:params[:supplier_id],order_id:params[:order_id],budget_id:budget_id,order_status:params[:order_status],qb_select:qb_select,numcopie:params[:numcopie]), class:"btn btn-#{classe}")}}.html_safe

      row_class = r.ancora_disp.to_f < 0 ? 'danger' : ''
      disponibili = number_to_currency(r.ancora_disp)
      # res << content_tag(:tr, content_tag(:td, biblioteca, title:row_title) +
      #                         content_tag(:td, r.numero_copie, title:'Numero copie') +
      #                         content_tag(:td, number_to_currency(r.spesi), title:'Spesi') +
      #                         content_tag(:td, disponibili, title:'Ancora disponibili') +
      #                         content_tag(:td, number_to_currency(r.assegnati), title:'Totale assegnato'), class:row_class)
      res << content_tag(:tr, content_tag(:td, biblioteca, title:row_title) +
                              content_tag(:td, r.numero_copie, title:'Numero copie') +
                              content_tag(:td, number_to_currency(r.spesi), title:'Spesi'), class:row_class)

    end
    return '' if cnt==0
    "#{heading} #{content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')}".html_safe
  end
  
  def sbct_items_short_list(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Titolo', class:'col-md-3') +
                            content_tag(:td, 'Prezzo listino', class:'col-md-1') +
                            content_tag(:td, 'Sconto', class:'col-md-1') +
                            content_tag(:td, '<b>Prezzo non corretto</b>'.html_safe, class:'col-md-1') +
                            content_tag(:td, 'Prezzo scontato', class:'col-md-1'), class:'danger')
    cnt = 0
    records.each do |r|
      cnt+=1
      res << content_tag(:tr, content_tag(:td, link_to(r.titolo,sbct_title_path(r.id_titolo))) +
                              content_tag(:td, r.listino) +
                              content_tag(:td, "#{r.discount}%") +
                              content_tag(:td, r.prezzo_copia) +
                              content_tag(:td, r.prezzo_scontato))
    end
    cnt == 0 ? '' : content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

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
    records.each do |r|
      cnt+=1; res << sbct_items_list_row(r,cnt)
    end
    cnt == 0 ? '' : content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_items_list_row(r,cnt)
    lnk = r.supplier_id.nil? ? '' : link_to(r.supplier_id, sbct_supplier_path(r.supplier_id), class:'btn btn-warning', target:'_suppliers')
    if r.budget_id.nil?
      budget_lnk = ''
    else
      budget_lnk = link_to(r.budget_id, sbct_budget_path(r.budget_id), class:'btn btn-warning', target:'_budgets')
    end
    if can? :manage, SbctItem
      edit_link = link_to(r.id, edit_sbct_item_path(r), class:'btn btn-warning', target:'_item')
    else
      edit_link = r.id
    end
    siglabib = r.siglabiblioteca
    siglabib << " (dest: #{r.destlibrary})" if !r.destlibrary.nil? 
    content_tag(:tr, content_tag(:td, cnt) +
                     content_tag(:td, link_to(r.titolo,sbct_title_path(r.id_titolo), target:'_blank')) +
                     content_tag(:td, edit_link) +
                     content_tag(:td, r.prezzo_scontato) +
                     content_tag(:td, r.numcopie) +
                     content_tag(:td, budget_lnk) +
                     content_tag(:td, r.order_status) +
                     content_tag(:td, lnk) +
                     content_tag(:td, siglabib))
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
                              content_tag(:td, number_to_currency(r.prezzo_scontato)) +
                              content_tag(:td, number_to_currency(r.prezzo_scontato.to_f*r.numcopie)) +
                              content_tag(:td, r.siglebct))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_items_order_list(sbct_order,records)
    rbudget = sbct_order.sbct_budget.snapshot
    tbudget = sbct_order.sbct_budget.snapshot
    res=[]
    heading = content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                               content_tag(:td, 'Budget', class:'col-md-1') +
                               content_tag(:td, 'Bibl', class:'col-md-1') +
                               content_tag(:td, 'Titolo', class:'col-md-4') +
                               content_tag(:td, 'Id_copia', class:'col-md-1') +
                               content_tag(:td, 'Costo', class:'col-md-1') +
                               content_tag(:td, 'Totale', class:'col-md-1') +
                               content_tag(:td, 'Residuo', class:'col-md-2'), class:'success')
    res << heading

    subtotale=lambda do |totale,siglabib,rbudget,tbudget|
      r = []
      residuo = tbudget[[siglabib,false]].to_f - totale[[siglabib,false]].to_f
      r << content_tag(:tr, content_tag(:td, '', colspan:4) +
                            content_tag(:td, "Uff. Acq.",colspan:2) +
                            content_tag(:td, "#{number_to_currency(totale[[siglabib,false]].to_f.round(2))}") +
                            content_tag(:td, "#{number_to_currency(residuo)}"), class:'warning')
      residuo = tbudget[[siglabib,true]].to_f - totale[[siglabib,true]].to_f
      r << content_tag(:tr, content_tag(:td, '', colspan:4) +
                            content_tag(:td, "Biblioteca",colspan:2) +
                            content_tag(:td, "#{number_to_currency(totale[[siglabib,true]].to_f.round(2))}", colspan:1) +
                            content_tag(:td, "#{number_to_currency(residuo)}"), class:'warning')
      r
    end

    siglabib = ''
    totale=Hash.new
    budget_detail=nil
    skip = false
    records.each do |r|
      r.prezzo_scontato = r.prezzo_scontato.to_f
      if r.siglabiblioteca != siglabib
        if !siglabib.blank?
          res << subtotale.call(totale,siglabib,rbudget,tbudget)
          res << heading
        end
        # A inizio loop il totale è uguale al prezzo della prima copia esaminata
        totale[[r.siglabiblioteca,r.qb]]=r.prezzo_scontato
        skip = false
      else
        if totale.has_key?([r.siglabiblioteca,r.qb])
          totale[[r.siglabiblioteca,r.qb]] += r.prezzo_scontato
        else
          totale[[r.siglabiblioteca,r.qb]] = r.prezzo_scontato
        end
        begin
          rbudget[[r.siglabiblioteca,r.qb]] -= r.prezzo_scontato
        rescue
          return "Errore cercando di eseguire rbudget[[r.siglabiblioteca,r.qb]] -= r.prezzo_scontato:<br/> #{$!} per r.prezzo_scontato #{r.prezzo_scontato} --- id_titolo #{r.id_titolo} id_copia #{r.id_copia} #{rbudget[[r.siglabiblioteca,r.qb]].class}<br/>r.prezzo_scontato=#{r.prezzo_scontato}<br/>#{r.siglabiblioteca} - qb: #{r.qb}".html_safe
        end
      end
      siglabib = r.siglabiblioteca
      residuo = rbudget[[siglabib,r.qb]].to_f - r.prezzo_scontato
      if residuo > 0
        tot_prog = totale[[siglabib,r.qb]]
      else
        tot_prog = '-'
        skip = true
      end
      res << sbct_items_order_list_row(r,tot_prog,residuo)
    end
    res << subtotale.call(totale,siglabib,rbudget,tbudget) if !siglabib.blank?
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_items_multibudget_order_list(sbct_order,records)
    res=[]
    heading = content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                               content_tag(:td, 'Budget', class:'col-md-1') +
                               content_tag(:td, 'Bibl', class:'col-md-1') +
                               content_tag(:td, 'Titolo', class:'col-md-4') +
                               content_tag(:td, 'Id_copia', class:'col-md-1') +
                               content_tag(:td, 'Costo', class:'col-md-1') +
                               content_tag(:td, '', class:'col-md-1') +
                               content_tag(:td, '', class:'col-md-2'), class:'success')
    res << heading

    siglabib = ''
    totale=Hash.new
    budget_detail=nil
    skip = false
    records.each do |r|
      r.prezzo_scontato = r.prezzo_scontato.to_f
      siglabib = r.siglabiblioteca
      residuo = 0
      tot_prog = 0
      res << sbct_items_order_list_row(r,tot_prog,residuo)
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end
  
  def sbct_items_order_list_row(r,tot_prog,residuo)
    if tot_prog=='-'
    else
      tot_prog = number_to_currency(tot_prog.round(2))
    end
    if residuo < 0
      checkval = false
      residuo = '-'
    else
      checkval = true
      residuo = number_to_currency(residuo)
    end
    content_tag(:tr, content_tag(:td, check_box_tag("item_ids[]", r.id_copia, checkval)) +
                     content_tag(:td, (r.qb==true ? 'Biblioteca' : 'Uff. Acq.' )) +
                     content_tag(:td, r.siglabiblioteca) +
                     content_tag(:td, link_to(r.titolo, sbct_title_path(r.id_titolo), target:'_blank')) +
                     content_tag(:td, link_to(r.id, edit_sbct_item_path(r), target:'_blank')) +
                     content_tag(:td, r.prezzo_scontato) +
                     content_tag(:td, tot_prog) +
                     content_tag(:td, residuo))
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
