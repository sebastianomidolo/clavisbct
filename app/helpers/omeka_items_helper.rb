# -*- coding: utf-8 -*-
module OmekaItemsHelper
  def omeka_items_list(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.title,r)))
    end
    res=content_tag(:tbody, res.join.html_safe)
    content_tag(:table, res, {class: 'table table-striped'})
  end

  def omeka_item_show(record)
    res=[]
    res << "Titolo: #{link_to(record.title, record.omeka_url)}"
    res << "<br/><b>Collezione:</b>"
    res << content_tag(:div, omeka_collection_hierarchy(record))
    content_tag(:div, res.join.html_safe)
  end
end
