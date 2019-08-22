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
    content_tag(:h2, text) +
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
end
