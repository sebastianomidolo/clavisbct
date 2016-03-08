# -*- coding: utf-8 -*-
module OpenShelfItemsHelper
  def open_shelf_item_toggle(item_id, deleted, sections, dest_section)
    if item_id.class == ClavisItem
      clavis_item = item_id
      item_id = item_id.id
    else
      clavis_item = ClavisItem.find(item_id)
    end

    if !deleted
      open_shelf_item = OpenShelfItem.find(item_id)
      os_section = open_shelf_item.os_section
    else
      os_section = ''
    end

    # if user_signed_in? and [6,9,12,17].include?(current_user.id)
    lnk=[]
    if can? :manage, OpenShelfItem or can? :toggle_item, OpenShelfItem
      if deleted
        disabled = dest_section.blank? ? true : false
        sections.each do |sec|
          lnk << link_to(sec, insert_open_shelf_item_path(item_id, format:'js', dest_section:sec), title:"Aggiungi a scaffale aperto #{sec}", class: 'btn btn-primary', remote: true, onclick: %Q{$('#item_#{item_id}').html('<b>inserimento...</b>')})
        end
      else
        # if [open_shelf_item.created_by,12,17].include?(current_user.id)
        if (can? :manage, OpenShelfItem or open_shelf_item.created_by==current_user.id) and not sections.include?(clavis_item.section)
          disabled = false
          btn_text = "Togli da #{open_shelf_item.os_section} (inserito da #{User.find(open_shelf_item.created_by).email})"
        else
          disabled = true
          btn_text = "Inserito da #{User.find(open_shelf_item.created_by).email} (#{clavis_item.section})"
        end
        lnk << link_to(btn_text, delete_open_shelf_item_path(item_id, format:'js', dest_section:dest_section), title:"Togli da scaffale aperto #{dest_section}", class: 'btn btn-danger', remote: true, disabled: disabled, onclick: %Q{$('#item_#{item_id}').html('<b>cancellazione...</b>')})
      end
    else
      # lnk = deleted ? 'magazzino' : 'scaffale aperto'
      lnk = os_section
    end
    lnk.join
  end

  def open_shelf_dewey_list(records,os_section)
    res=[]
    records.each do |r|
      res << open_shelf_dewey_list_row(r,os_section)
    end
    res=content_tag(:tbody, res.join("\n").html_safe)
    res=content_tag(:table, res, {class: 'table table-striped'})
  end

  def open_shelf_dewey_list_row(record,os_section=nil,clavis_items=[])
    res=[]
    dw = record['dewey']
    lnk = clavis_items.size == 0 ? link_to(dw, titles_open_shelf_items_path(format:'js',class_id:record['class_id'],dest_section:os_section) ,remote: true) : link_to(content_tag(:b, dw) + " [CHIUDI]", titles_open_shelf_items_path(format:'js',class_id:record['class_id'],dest_section:os_section,close:true) ,remote: true)
    res << content_tag(:tr, content_tag(:td, lnk) +
                       content_tag(:td, record['count']), id:"class_#{record['class_id']}")
    res << content_tag(:tr, content_tag(:td, clavis_items_ricollocazioni(clavis_items,os_section)),
                       id:"class_#{record['class_id']}_titles") if clavis_items.size>0
    res.join.html_safe
  end
  
  def open_shelf_item_show(record)
    "Magazzino: #{record.collocazione_magazzino} --- Scaffale aperto: #{record.collocazione_scaffale_aperto} (#{record.os_section})"
  end

  def open_shelf_items_estrazione_da_magazzino(records,verb)
    res=[]
    if verb=='estrai'
      records.each do |r|
        if r['os_section']!=r['section']
          item_info = "#{r['os_section']} #{r['collocazione_scaffale_aperto']}"
          titolo = link_to("#{r['titolo']}", ClavisItem.clavis_url(r['item_id']),class:'',:target=>'_blank')
          coll = "<b>#{r['collocazione_magazzino']}</b><br/>#{r['item_status_label']}/#{r['loan_status_label']}<br/>#{r['loan_class_label']}".html_safe
          res << content_tag(:tr,
                             content_tag(:td, content_tag(:b, r['section']), style:'width:10%') +
                             content_tag(:td, coll, style:'width:20%') +
                             content_tag(:td, titolo, style:'width:60%') +
                             content_tag(:td, item_info))
        else
          item_info = link_to("<b>Già ricollocato</b>".html_safe,
                              ClavisItem.clavis_url(r['item_id'],:show),:target=>'_blank')
          res << content_tag(:tr,
                             content_tag(:td, content_tag(:b, r['section']), style:'width:10%') +
                             content_tag(:td, content_tag(:b, r['collocazione_scaffale_aperto']), style:'width:20%') +
                             content_tag(:td, r['titolo'], style:'width:60%') +
                             content_tag(:td, item_info))
        end
      end
    else
      records.each do |r|
        if r['os_section']!=r['section']
          if r['loan_status'] == 'A' and r['item_status'] == 'F'
            item_info = link_to("ricolloca come #{r['os_section']} #{r['collocazione_scaffale_aperto']}",
                                ClavisItem.clavis_url(r['item_id'],:ricolloca),class:'btn btn-success',:target=>'_blank')
          else
            item_info = link_to("#{r['os_section']} #{r['collocazione_scaffale_aperto']} (non ricollocabile)",
                                ClavisItem.clavis_url(r['item_id']),class:'',:target=>'_blank')
          end
          item_info << "<br/>Stato: #{r['item_status_label']}/#{r['loan_status_label']}".html_safe
          res << content_tag(:tr,
                             content_tag(:td, item_info) +
                             content_tag(:td, "ex #{r['collocazione_magazzino']}") +
                             content_tag(:td, r['titolo']))
        else
          item_info = link_to("<b>#{r['os_section']} #{r['collocazione_scaffale_aperto']}</b>".html_safe,
                              ClavisItem.clavis_url(r['item_id'],:show),:target=>'_blank')
          item_info << "<br/>Stato: #{r['item_status_label']}/#{r['loan_status_label']}".html_safe
          # item_info << "<br/>#{r['loan_status_label']}".html_safe
          res << content_tag(:tr,
                             content_tag(:td, item_info) +
                             content_tag(:td, r['custom_field1']) +
                             content_tag(:td, r['titolo']), class:'success')
        end
      end
    end
    res=content_tag(:tbody, res.join.html_safe)
    res=content_tag(:table, res, {class: 'table table-bordered'})
  end

  def open_shelf_items_estrazione_da_magazzino_index(records,section,page,per_page,verb,escludi_in_prestito,text_filter,escludi_ricollocati)
    res=[]
    if verb=='estrai'
      lnk = link_to('a Scaffale aperto',
                    estrazione_da_magazzino_open_shelf_items_path(dest_section:section,page:page,per_page:per_page,
                                                                  qs:text_filter,
                                                                  escludi_ricollocati:escludi_ricollocati,
                                                                  verb:'ricolloca',escludi_in_prestito:escludi_in_prestito),
                    title:"Ricolloca i volumi nella sezione #{section}", class: 'btn btn-info')
      pdflnk = link_to('PDF',
                    estrazione_da_magazzino_open_shelf_items_path(dest_section:section,page:page,per_page:per_page,
                                                                  qs:text_filter,
                                                                  escludi_ricollocati:escludi_ricollocati,
                                                                  escludi_in_prestito:escludi_in_prestito,
                                                                  verb:'estrai',format:'pdf'),
                    title:"Stampa PDF", class: 'btn btn-info')
      res << content_tag(:h3, "Spostamento di volumi da Magazzino #{lnk} - #{pdflnk}".html_safe)

      
      # csvlnk = link_to('CSV',
      #              estrazione_da_magazzino_open_shelf_items_path(dest_section:section,page:page,per_page:per_page,
      #                                                            verb:'estrai',format:'csv'),
      #              title:"CSV (solo libri non in prestito)", class: 'btn btn-success')
      # csvlnk=''
      # res << content_tag(:h2, "Lista ordinata per collocazione a magazzino #{pdflnk} #{csvlnk}".html_safe)
      range=records.collect {|r| r['collocazione_magazzino']}.sort
      first=range.first
      last=range.last
    else
      lnk = link_to('da Magazzino',
                    estrazione_da_magazzino_open_shelf_items_path(dest_section:section,page:page,per_page:per_page,
                                                                  qs:text_filter,
                                                                  escludi_ricollocati:escludi_ricollocati,
                                                                  verb:'estrai',escludi_in_prestito:escludi_in_prestito),
                    title:"Produce una lista di volumi in ordine di collocazione", class: 'btn btn-info')
      res << content_tag(:h3, "Spostamento di volumi #{lnk} a scaffale aperto".html_safe)
      res << content_tag(:h2, "Lista di volumi ordinata per collocazione a scaffale aperto")
      range=records.collect {|r| r['collocazione_scaffale_aperto']}.sort
      first=range.first
      last=range.last
    end
    res << content_tag(:div, "#{records.size} volumi: da <b>#{first}</b> a <b>#{last}</b>".html_safe)

    res << open_shelf_items_paginate(page, per_page, section, verb, escludi_in_prestito, text_filter, escludi_ricollocati)

    res.join.html_safe
  end

  def open_shelf_items_paginate(page, per_page, section, verb, escludi_in_prestito, text_filter, escludi_ricollocati)
    res=''
    res << %Q{<form action="/open_shelf_items/estrazione_da_magazzino" method="get">}
    res << %Q{<input name="per_page" type="hidden" value="#{per_page}" />}
    res << %Q{<input name="dest_section" type="hidden" value="#{section}" />}
    res << %Q{<input name="verb" type="hidden" value="#{verb}" />}
    res << %Q{#{check_box_tag :escludi_in_prestito, true, escludi_in_prestito}}
    res << %Q{#{label_tag(:escludi_in_prestito, 'Escludi i libri in prestito')}}
    res << %Q{<br/>#{check_box_tag :escludi_ricollocati, true, escludi_ricollocati}}
    res << %Q{#{label_tag(:escludi_ricollocati, 'Escludi i libri già ricollocati')}}
    res << %Q{<br/>Filtra per parole nel titolo: #{text_field_tag :qs, text_filter}}

    totale=OpenShelfItem.conta(section, escludi_in_prestito, text_filter, escludi_ricollocati)
    if (totale%per_page)==0
      num_pages=totale/per_page
    else
      num_pages=totale/per_page+1
    end
    # num_pages=totale/per_page
    # res << "totale #{totale} num_pages: #{num_pages}"

    cnt=1
    if num_pages>1
      res << %Q{<select name="page" size="1" onchange="submit()">}
      (1..num_pages).each do |p|
        sel = p==page ? %Q{ selected="selected"} : ''
        from=(p-1)*per_page+1
        to = p*per_page < totale ? p*per_page : totale
        res << %Q{<option value="#{p}"#{sel}>#{cnt}: #{from}-#{to}</option>}
        cnt+=1
        # links << link_to(p, estrazione_da_magazzino_open_shelf_items_path(dest_section:section,page:p,per_page:per_page))
      end
      res << "</select>"
    end
    res << "</form>"
  end

  def open_shelf_items_riepilogo_ricollocazione
    return '' if !can? :manage, OpenShelfItem
    res=[]
    sql=%Q{WITH summary AS (
   select os.item_id,cl.event_date
     FROM open_shelf_items os JOIN clavis.changelog cl
      on(os.item_id=cl.object_id and cl.user_id=578 and cl.event_type='B' and object_class='Item')
  )
    SELECT date_trunc('hour', t1.event_date) as "Data e ora",count(*) as "Numero volumi"
      FROM summary AS t1
        LEFT OUTER JOIN summary AS t2 ON (t1.item_id = t2.item_id)
        AND (t1.event_date > t2.event_date)
      WHERE t2.item_id IS NULL
        GROUP BY date_trunc('hour', t1.event_date)
        ORDER BY date_trunc('hour', t1.event_date)}

    prec_giorno=''
    totale_g_p=totale_g_m=0
    totale_m=totale_p=0
    giorno=''
    colore_p='#cdeb8e'
    colore_m='#a7c7dc'
    ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
      tempo=r['Data e ora']
      ora = tempo[11..12].to_i
      if ora > 13
        colore=colore_p
      else
        colore=colore_m
      end
      anno,mese,g=r['Data e ora'][0..9].split('-')
      giorno="#{g}-#{mese}-#{anno}"
      volumi=r['Numero volumi'].to_i
      if prec_giorno!='' and prec_giorno!=giorno
        res << content_tag(:tr,
                           content_tag(:td, "Totale giornata #{prec_giorno}", style:'width:20%') +
                           content_tag(:td, "#{totale_m} + #{totale_p}: #{totale_m+totale_p}".html_safe),
                           style:"background-color: #eab92d")
        totale_m=totale_p=0
      end
      if ora > 13
        totale_p+=volumi
        totale_g_p+=volumi
      else
        totale_m+=volumi
        totale_g_m+=volumi
      end
      res << content_tag(:tr,
                         content_tag(:td, "#{giorno}, ore #{ora}", style:'width:20%') +
                         content_tag(:td, "#{volumi}" ),
                         style:"background-color: #{colore}")
      prec_giorno=giorno
    end
    res << content_tag(:tr,
                       content_tag(:td, "Totale giornata #{giorno}", style:'width:20%') +
                       content_tag(:td, "#{totale_m} + #{totale_p}: #{totale_m+totale_p}"),
                       style:"background-color: #eab92d")
    res << content_tag(:tr,
                       content_tag(:td, "Totale generale", style:'width:20%') +
                       content_tag(:td, "#{totale_g_m} + #{totale_g_p}: #{totale_g_m+totale_g_p}"),
                       style:"background-color: #6bba70")

    res=content_tag(:tbody, res.join.html_safe)
    content_tag(:table, res, {class: 'table table-bordered'})
  end

end
