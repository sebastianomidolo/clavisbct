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
  end

  def closed_stack_item_requests_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r['piano']) +
                              content_tag(:td, r['collocazione']) +
                              content_tag(:td, link_to(r['lastname'], print_request_clavis_patron_path(r['patron_id'], :format=>:pdf))) +
                              content_tag(:td, r['request_time']) +
                              content_tag(:td, r['title']))
    end
    content_tag(:table, res.join.html_safe, class:'table text-success')
  end
  
end
