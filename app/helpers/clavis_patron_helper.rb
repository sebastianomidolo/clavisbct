module ClavisPatronHelper
  def clavis_patron_show(patron)
    ticket=patron.richieste_a_magazzino_attive
    ticket = " - #{content_tag(:b, ticket)}" if !ticket.blank?
    content_tag(:h2, "Richieste a magazzino di #{patron.to_label}#{ticket}".html_safe) +
      content_tag(:div, clavis_patron_csir_pending(patron)) +
      content_tag(:div, clavis_patron_csir_print_queue(patron)) +
      content_tag(:div, clavis_patron_csir_printed(patron))
  end
  def clavis_patron_csir_pending(patron)
    req=ClosedStackItemRequest.list(patron.id,pending=true,printed=false)
    "richieste pendenti (da confermare al banco prestiti): #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron)
  end
  def clavis_patron_csir_print_queue(patron)
    req=ClosedStackItemRequest.list(patron.id,pending=false,printed=false)
    "richieste da stampare: #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron)
  end
  def clavis_patron_csir_printed(patron,date_range='today')
    req=ClosedStackItemRequest.list(patron.id,pending=false,printed=true)
    "richieste stampate: #{req.size}".html_safe +
      closed_stack_item_requests_index(req,patron)
  end
end
