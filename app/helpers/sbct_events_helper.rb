# coding: utf-8
module SbctEventsHelper

  def sbct_event_types_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'Tipologia evento', class:'col-md-2 text-left'), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.event_type_id, edit_sbct_event_type_path(r), class:'btn btn-success')) +
                              content_tag(:td, r.label))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end


  def sbct_events_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'Titolo', class:'col-md-4') +
                            content_tag(:td, 'Evento', class:'col-md-4') +
                            content_tag(:td, 'Copie'.html_safe, class:'col-md-1', title:'Copie selezionate / richieste') +
                            content_tag(:td, 'Convalida', class:'col-md-2'), class:'warning')
    prev_event_id=0
    records.each do |r|
      lnktit = r.id_titolo.blank? ? '' : link_to(r.titolo, sbct_title_path(r.id_titolo.to_i, event_id:r.event_id))
      status_convalida = r.stato_convalida.blank? ? 'ancora niente da convalidare' : r.stato_convalida
      chiusura_forzata = r.closed=='t' ? '<br/><span class="label label-info">chiuso</span>' : ''
      status_convalida_message="#{status_convalida}#{chiusura_forzata}".html_safe
      if current_user.role?(['AcquisitionManager','AcquisitionStaffMember']) and !lnktit.blank?
        tl=link_to(status_convalida, edit_sbct_l_event_title_path("#{r.event_id},#{r.id_titolo}"), class:'btn btn-info')
        lnktit << "<br/>#{tl}".html_safe
        lnktit << content_tag(:h5, content_tag(:em, r.response_note), title:'Nota da Ufficio Acquisti')
      end

      if r.ean.blank?
        img_link = ''
      else
        img_link = link_to(image_tag("https://covers.biblioteche.cloud/covers/#{r.ean}/C/0/P", {width:"80"}),
                           sbct_title_path(r.id_titolo), target:'_blank')
      end
      if prev_event_id != r.event_id
        if r.numtitoli.to_i > 1
          evmsg = "<br/>(#{r.numtitoli} titoli)<br/><em>#{r.description}</em>"
        else
          evmsg = "<br/><em>#{r.description}</em>"
        end
        evmsg << "<br/>#{event_dates(r)}"
      else
        evmsg = ''
      end
      prev_event_id = r.event_id
      lnkev = link_to(r.name, sbct_event_path(r)) + evmsg.html_safe
      res << content_tag(:tr, content_tag(:td, img_link) +
                              content_tag(:td, lnktit) +
                              content_tag(:td, lnkev, title:"evento creato da #{r.creato_da}") +
                              content_tag(:td, "#{r.selected_items_cnt}/#{r.requested_items_cnt}") +
                              content_tag(:td, status_convalida_message))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def event_dates(event)
    res = []
    if event.event_start == event.event_end
      if !event.event_start.nil?
        res << "Data evento: #{event.event_start}"
      else
        res << "Evento senza data"
      end
    else
      res << "Inizio: #{event.event_start}" if !event.event_start.nil?
      res << "Fine: #{event.event_end}" if !event.event_end.nil?
    end
    res.join('<br/>')
  end

  def l_event_titles_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Evento', class:'col-md-3') +
                            content_tag(:td, 'Titolo', class:'col-md-3') +
                            content_tag(:td, "Chiesto&nbsp;da".html_safe, class:'col-md-1') +
                            content_tag(:td, 'Il', class:'col-md-1') +
                            content_tag(:td, 'NumCopie', class:'col-md-1') +
                            content_tag(:td, 'Note', class:'col-md-3'), class:'success')
    records.each do |r|
      chiesto_il = r.request_date.to_s
      chiesto_il << %Q{<br/><span title="Data ultimo aggiornamento richiesta"></span>}
      res << content_tag(:tr, content_tag(:td, link_to(r.name, sbct_event_path(r.event_id))) +
                              content_tag(:td, link_to(r.titolo, edit_sbct_l_event_title_path([r.event_id,r.id_titolo].join(',')))) +
                              content_tag(:td, r.req_user) +
                              content_tag(:td, chiesto_il.html_safe) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, r.notes) )
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def l_event_titles_list_for_librarians(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Titolo', class:'col-md-7') +
                            content_tag(:td, "Chiesto&nbsp;da".html_safe, class:'col-md-1') +
                            content_tag(:td, 'Il', class:'col-md-1') +
                            content_tag(:td, 'NumCopie', class:'col-md-3'), class:'success')
    records.each do |r|
      chiesto_il = r.request_date.to_s
      chiesto_il << %Q{<br/><span title="Data ultimo aggiornamento richiesta"></span>}
      res << content_tag(:tr, content_tag(:td, link_to(r.titolo, sbct_title_path(r.id_titolo, target:'_new'))) +
                              content_tag(:td, r.req_user) +
                              content_tag(:td, chiesto_il.html_safe) +
                              content_tag(:td, r.numcopie))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  # Genera un bottone per l'acquisto (selezione) di una copia per la biblioteca corrente
  # legandola all'evento stesso (via copie.event_id)
  def ordina_copie_se_interessato_a(l_event_title,user)
    return '' if l_event_title.validated.class != TrueClass
    l = ClavisLibrary.find(user.clavis_librarian.default_library_id)
    label_evento = link_to(l_event_title.sbct_event.to_label, sbct_event_path(l_event_title.event_id), target:'_new')
    return if l_event_title.numero_copie_selezionabili < 1
    res = []
    if can? :new, SbctItem
      lnk = "<b>Aggiungi copia per #{l.siglabct} per evento (#{l.shortlabel.strip})</b>".html_safe
      res << content_tag(:tr, content_tag(:td, "Copie richieste", class:'col-md-3') +
                              content_tag(:td, l_event_title.numcopie, class:'col-md-9'))
      res << content_tag(:tr, content_tag(:td, "Residue") +
                              content_tag(:td, l_event_title.numero_copie_selezionabili))
      res << content_tag(:tr, content_tag(:td, "Note") +
                              content_tag(:td, l_event_title.notes))
      res << content_tag(:tr, content_tag(:td, "Note Uff Acquisti") +
                                    content_tag(:td, l_event_title.response_note))

      if l_event_title.numero_copie_selezionabili > 0
        res << content_tag(:tr, content_tag(:td, link_to(lnk, insert_item_sbct_title_path(event_id:l_event_title.event_id), class:'btn btn-warning'), {colspan:2}))
      end

    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end
  
end
