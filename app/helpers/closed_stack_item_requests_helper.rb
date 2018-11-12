module ClosedStackItemRequestsHelper

  def closed_stack_item_requests_list(dng_session,target_div)
    res = []
    patron=ClavisPatron.find(dng_session.patron_id)
    patron.closed_stack_item_requests.each do |ir|
      item=ClavisItem.find(ir.item_id)
      lnk=link_to(item.title, ClavisManifestation.clavis_url(item.manifestation_id, :opac))

      url="https://#{request.host_with_port}#{item_delete_closed_stack_item_request_path(ir,dng_user:patron.opac_username,target_div:target_div,format:'js')}"
      canc_lnk=link_to('cancella',url,remote:true,title:'Elimina questa richiesta', method: :get, data: {confirm: 'Vuoi eliminare la richiesta?'})

      res << content_tag(:tr, content_tag(:td, item.la_collocazione) +
                         content_tag(:td, lnk) +
                         content_tag(:td, ir.request_time) +
                         content_tag(:td, canc_lnk))
    end
    return '' if res == []
    # <h3 class="pending"><i class="fa fa-clock-o"></i> Prestiti in elaborazione</h3>
                           
    content_tag(:h3, %Q{<i id="print_request_tag" class="fa fa-print" aria-hidden="true"></i> Richieste a magazzino}.html_safe, class:'pending') +
      content_tag(:table, res.join.html_safe, class:'table text-success')

    content_tag(:h3, %Q{Richieste a magazzino}.html_safe) +
      content_tag(:table, res.join.html_safe, class:'table text-success')
  end

  def closed_stack_item_requests_index(records, patron)
    return if records.size==0
    res=[]
    confirm_request=false
    records.each do |r|
      confirm_request = true if r.daily_counter.nil?
      res << content_tag(:tr, content_tag(:td, r.piano) +
                              content_tag(:td, r.collocazione) +
                              content_tag(:td, r.request_time.in_time_zone('Europe/Rome')) +
                              content_tag(:td, r.daily_counter) +
                              content_tag(:td, r['title']))
    end
    lnk = "https://#{request.host_with_port}#{confirm_request_closed_stack_item_request_path(patron.id, format:'js')}"
    if confirm_request
      cmd = %Q{<span id="conferma_richieste">#{link_to('<b>[Conferma le richieste]</b>'.html_safe, lnk,remote:true,title:'Invia richieste alla coda di stampa', method: :get, data: {confirm: 'Confermi invio richieste?'})}</span>}.html_safe
    else
      cmd=''
    end
    ids = records.collect{|x| x.item_id}
    link = link_to('In Clavis', ClavisItem.clavis_url(ids))
    content_tag(:h2, "#{cmd}".html_safe) +
      content_tag(:table, res.join.html_safe, class:'table text-success') +
      content_tag(:p, link)
  end

  def closed_stack_item_requests_patrons_index
    res = []
    res << content_tag(:h3, "Richieste di oggi (ultimo contatore giornaliero: <b>#{DailyCounter.last.id}</b>)".html_safe)
    res << content_tag(:h2, "Da confermare")
    res << closed_stack_item_requests_patrons(ClosedStackItemRequest.patrons(true,false))
    res << content_tag(:h2, "Da stampare")
    res << closed_stack_item_requests_patrons(ClosedStackItemRequest.patrons(false,false))
    res << content_tag(:h2, "Stampate")
    res << closed_stack_item_requests_patrons(ClosedStackItemRequest.patrons(false,true))
    res.join.html_safe
  end

  def closed_stack_item_requests_patrons(records)
    res=[]
    records.each do |r|
      lnk1 = link_to("<b>#{r['barcode']}</b>".html_safe, ClavisPatron.clavis_url(r['patron_id'],:newloan), target:'_blank')
      # lnk2 = link_to("<b>#{r['lastname']}</b>".html_safe, closed_stack_item_requests_path(patron_id:r['patron_id']))
      lnk2 = link_to("<b>#{r['lastname']}</b>".html_safe, clavis_patron_path(r['patron_id']))
      res << content_tag(:tr, content_tag(:td, lnk1, class:'col-md-2') +
                              content_tag(:td, lnk2, class:'col-md-2') +
                              content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe, class:'table text-success')
  end


  
end
