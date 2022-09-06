# coding: utf-8
module ClavisPatronHelper
  def clavis_patron_show(patron,message=nil,da_clavis=false)
    ticket=patron.csir_tickets.join(', ')
    ticket = " - #{content_tag(:b, ticket)} -" if !ticket.blank?
    r1=clavis_patron_csir_pending(patron,da_clavis)
    r2=clavis_patron_csir_print_queue(patron,da_clavis)
    r3=clavis_patron_csir_printed(patron,da_clavis)
    r4=clavis_patron_csir_archived(patron,da_clavis)
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
  def clavis_patron_csir_pending(patron,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,pending=true,printed=false)
    return '' if req.size==0
    "richieste pendenti (da confermare al banco prestiti): #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron,da_clavis)
  end
  def clavis_patron_csir_print_queue(patron,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,pending=false,printed=false)
    return '' if req.size==0
    "richieste confermate, da stampare: #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron,da_clavis)
  end
  def clavis_patron_csir_printed(patron,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,pending=false,printed=true)
    return '' if req.size==0
    "richieste stampate: #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron,da_clavis)
  end
  def clavis_patron_csir_archived(patron,da_clavis=false)
    req=ClosedStackItemRequest.list(patron.id,pending=false,printed=true,today=true,archived=true)
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
    cnt = 0
    records.each do |r|
      cnt += 1
      lnks = r.patron_ids.split(',').map {|i| link_to(i, ClavisPatron.clavis_url(i), target:'_blank')}

      res << content_tag(:tr, content_tag(:td, cnt) +
                              content_tag(:td, "#{r.lastname}<br/>#{r.opac_usernames.split(',').join(' ; ')}".html_safe) +
                              content_tag(:td, r.name) +
                              content_tag(:td, link_to("[allinea da Clavis]", duplicates_clavis_patrons_path(patron_ids:r.patron_ids)),title:'Si può fare click qui dopo avere effettuato lo schiacciamento della doppia iscrizione per questo utente, per avere la lista aggiornata senza aspettare domani') +
                              content_tag(:td, r.birth_city) +
                              content_tag(:td, r.birth_date) +
                              content_tag(:td, lnks.join("<br/>").html_safe))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

end
