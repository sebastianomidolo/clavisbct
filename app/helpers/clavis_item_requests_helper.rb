# coding: utf-8

module ClavisItemRequestsHelper


  def clavis_item_requests_index(records, request_date=nil)
    res=[]

    if request_date.nil?
      res << content_tag(:tr, content_tag(:th, "Data", class:'col-md-2') + content_tag(:th, "Numero prenotazioni"))
      records.each do |r|
        res << content_tag(:tr, content_tag(:td,
                                            link_to(r.request_date.to_date,
                                                    clavis_item_requests_path(request_date:r.request_date.to_s[0..9]))) +
                                content_tag(:td, r.count))
      end
    else
      res << content_tag(:tr, content_tag(:th, "Biblioteca di destinazione", class:'col-md-2') + content_tag(:th, "Numero prenotazioni"))
      records.each do |r|
        res << content_tag(:tr, content_tag(:td, link_to(r.label,
                                                         clavis_item_requests_link_to_item_search(request_date,r.library_id))) +
                                content_tag(:td, r.count))
      end
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def clavis_item_requests_link_to_item_search(request_date,library_id)
    item_ids = ClavisItemRequest.item_ids(library_id,request_date)
    "https://clavisbct.comperio.it/clavis_items?item_ids=#{item_ids}&amp;pdf_template=rawlist&amp;per_page=999999&amp;request_date=#{request_date}"
  end

end
