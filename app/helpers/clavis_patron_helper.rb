module ClavisPatronHelper
  def clavis_patron_show(patron)
    "Informazioni su utente #{patron.to_label}".html_safe +
      content_tag(:div, clavis_patron_csir_pending(patron)) +
      content_tag(:div, clavis_patron_csir_print_queue(patron,45)) +
      content_tag(:div, clavis_patron_csir_printed(patron)) +
      content_tag(:div, clavis_patron_csir_printed(patron,'all'))
  end
  def clavis_patron_csir_pending(patron)
    req=ClosedStackItemRequest.list(patron.id,pending=true,printed=false)
    "richieste pendenti (da confermare al banco prestiti - #{patron.to_label}) : #{req.size}"
  end
  def clavis_patron_csir_print_queue(patron,daily_counter)
    req=ClosedStackItemRequest.list(patron.id,pending=false,printed=false)
    "richieste da stampare (numero progressivo: #{daily_counter}) : #{req.size}"
  end
  def clavis_patron_csir_printed(patron,date_range='today')
    "richieste stampate (date_range: #{date_range})"
  end
end
