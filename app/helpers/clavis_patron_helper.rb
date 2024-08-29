# coding: utf-8
module ClavisPatronHelper

  def clavis_patron_notifiche_pronti_al_prestito_non_confermate(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Barcode', class:'col-md-1') +
                            content_tag(:td, 'ActionDate', class:'col-md-3') +
                            content_tag(:td, 'Bibl', class:'col-md-1') +
                            content_tag(:td, 'ItemTitle', class:'col-md-2') +
                            content_tag(:td, 'Stato', class:'col-md-1') +
                            content_tag(:td, 'Canale', class:'col-md-1') +
                            content_tag(:td, 'Ultimo Stato', class:'col-md-6'), class:'success')

    prec_barcode=nil
    @records.each do |r|
      lnk = link_to(r['barcode'], ClavisPatron.clavis_url(r['patron_id']), target:'_new')
      preferred_channels = r['contact_pref']=='1' ? "<br/>Pref: #{r['contact_type']}".html_safe : '<br/>no'.html_safe
      preferred_channels = "<br/><pre>#{r['contact_types']}\n#{r['contact_prefs']}</pre>".html_safe
      cnl = r['last_channel'].blank? ? '' : " (#{r['last_channel']})"
      lo_stato = r['last_state'].blank? ? '' : "#{r['last_state']}#{cnl}"
      if prec_barcode!=r['barcode'] and !prec_barcode.nil?
        res << content_tag(:tr, content_tag(:td, '<hr/>'.html_safe, {colspan:8}))
      end
      prec_barcode = r['barcode']
      res << content_tag(:tr, content_tag(:td, lnk + preferred_channels) +
                              content_tag(:td, "#{r['action_date']}<br/>notif_id: #{r['notification_id']}".html_safe) +
                              content_tag(:td, r['action_library_id']) +
                              content_tag(:td, "#{link_to(r['item_title'], ClavisItem.clavis_url(r['item_id']))}<br/>#{r['item_id']}".html_safe) +
                              content_tag(:td, r['state']) +
                              content_tag(:td, r['n_channel']) +
                              content_tag(:td, "#{lo_stato}<br/>#{r['notes']}".html_safe, title:r['notes']))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def clavis_patron_show(patron,library=nil,message=nil,da_clavis=false)
    ticket=patron.csir_tickets(library.id).join(', ')
    ticket = " - #{content_tag(:b, ticket)} -" if !ticket.blank?
    r1=clavis_patron_csir_pending(patron,library,da_clavis)
    r2=clavis_patron_csir_print_queue(patron,library,da_clavis)
    r3=clavis_patron_csir_printed(patron,library,da_clavis)
    r4=clavis_patron_csir_archived(patron,library,da_clavis)
    message = "" if message.nil?
    return '' if message+r1+r2+r3+r4==''
    if message.blank?
      script = content_tag(:script, "jQuery('.user_message').hide();".html_safe)
    else
      script = ''
    end
    text="Richieste a magazzino di #{patron.to_label}#{ticket}".html_safe
    if da_clavis
      text = link_to(text, "https://#{request.host_with_port}/#{clavis_patron_path(patron.id)}")
    end
    content_tag(:h4, text) +
      content_tag(:div, message, class:'user_message') +
      content_tag(:div, r1) +
      content_tag(:div, r2) +
      content_tag(:div, r3) +
      content_tag(:div, r4) + script
  end
  def clavis_patron_csir_pending(patron,library,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,library.id,pending=true,printed=false)
    return '' if req.size==0
    "richieste pendenti (da confermare al banco prestiti): #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron,da_clavis)
  end
  def clavis_patron_csir_print_queue(patron,library,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,library.id,pending=false,printed=false)
    return '' if req.size==0
    "richieste confermate, da stampare: #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron,da_clavis)
  end
  def clavis_patron_csir_printed(patron,library,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,library.id,pending=false,printed=true)
    return '' if req.size==0
    "richieste stampate: #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron,da_clavis)
  end
  def clavis_patron_csir_archived(patron,library,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,library.id,pending=false,printed=true,today=true,archived=true)
    return '' if req.size==0
    "richieste archiviate: #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron,da_clavis)
  end
  def clavis_patron_mancato_ritiro(records)
    res=[]
    records.each do |r|
      lnk = link_to("<b>#{r['patron']}</b>".html_safe, ClavisPatron.clavis_url(r['patron_id']), target:'_blank')
      res << content_tag(:tr, content_tag(:td, lnk, class:'col-md-3') +
                              content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def clavis_patron_loans_overlaps(patron)
    res = []
    patron.find_common_loans_patrons.each do |p|
      res << content_tag(:tr, content_tag(:td, "#{p['numtit']} titoli in comune su #{p['totale']}") +
                              content_tag(:td, link_to("#{p['name']} #{p['lastname']}",loans_analysis_clavis_patron_path(p['patron_id']))) +
                              content_tag(:td, p['common_manifestations']))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def clavis_patrons_duplicates(records)
    res = []
    res << content_tag(:tr, content_tag(:td, '#', class:'col-md-1') +
                            content_tag(:td, 'Cognome', class:'col-md-2') +
                            content_tag(:td, 'Barcodes', class:'col-md-1') +
                            content_tag(:td, 'Nome&nbsp;utente opac'.html_safe, class:'col-md-2') +
                            content_tag(:td, 'Date iscrizione', class:'col-md-3') +
                            content_tag(:td, 'Iscritto&nbsp;da'.html_safe, class:'col-md-1') +
                            content_tag(:td, 'Biblioteca'.html_safe, class:'col-md-1') +
                            content_tag(:td, '-', class:'col-md-1'), class:'success')
    cnt = 0
    records.each do |r|
      cnt += 1
      #ptr = r.patron_ids.split(',')
      #lnks = ptr.map {|i| link_to(i, ClavisPatron.clavis_url(i), target:'_blank')}
      res << content_tag(:tr, content_tag(:td, cnt) +
                              content_tag(:td, "#{r.lastname}") +
                              content_tag(:td, "#{link_to(r.primo_barcode,ClavisPatron.clavis_url(r.primo_iscritto_id))}<br/>#{link_to(r.ultimo_barcode,ClavisPatron.clavis_url(r.ultimo_iscritto_id))}".html_safe, title:'Vai alla scheda utente') +
                              content_tag(:td, "#{link_to(r.primo_username,ClavisPatron.clavis_url(r.primo_iscritto_id,:newloan))}<br/>#{link_to(r.ultimo_username,ClavisPatron.clavis_url(r.ultimo_iscritto_id,:newloan))}".html_safe, title:'Vai al banco prestiti') +
                              content_tag(:td, "#{r.primo_data_iscrizione}<br/>#{r.ultimo_data_iscrizione}".html_safe) +
                              content_tag(:td, "#{r.primo_iscrivente}<br/>#{r.ultimo_iscrivente}".html_safe) +
                              content_tag(:td, "#{r.primo_library}<br/>#{r.ultimo_library}".html_safe) +
                              content_tag(:td, link_to("[allinea]", duplicates_clavis_patrons_path(patron_ids:r.patron_ids,library_id:params[:library_id])),title:'Si può fare click qui dopo avere effettuato lo schiacciamento della doppia iscrizione per questo utente, per avere la lista aggiornata senza aspettare domani'))
      # res << content_tag(:tr, content_tag(:td, content_tag(:pre, ClavisPatron.sql_per_schiacciamento(ptr[1],ptr[0])), colspan:"7"))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-striped')
  end

  def clavis_patrons_sync_page
    res = []
    last_patron = ClavisPatron.last
    lnktext = last_patron.barcode
    res << content_tag(:tr, content_tag(:td, "Ultimo utente iscritto (patron_id #{last_patron.id})") +
                            content_tag(:td, "#{link_to(lnktext, ClavisPatron.clavis_url(last_patron.id))} #{last_patron.access_note}".html_safe))
    res << content_tag(:tr, content_tag(:td, "Data iscrizione") +
                            content_tag(:td, "#{last_patron.date_created}"))

    if !params[:check_new].blank?
      ClavisPatron.allinea_da_clavis
      new_last_patron_id = ClavisPatron.last.id
      if new_last_patron_id != last_patron.id
        res << content_tag(:tr, content_tag(:td, "Aggiornamento: #{new_last_patron_id-last_patron.id} nuovi iscritti (ultimo:  #{new_last_patron_id})"))
      else
        res << content_tag(:tr, content_tag(:td, "Non ci sono nuovi iscritti dopo #{last_patron.barcode}"))
      end
    else
      res << content_tag(:tr, content_tag(:td, link_to("Controlla se ci sono nuovi iscritti", closed_stack_item_requests_path(check_new:true),class:'btn btn-success')))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

end
