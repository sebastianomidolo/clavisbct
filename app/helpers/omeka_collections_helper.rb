# -*- coding: utf-8 -*-
module OmekaCollectionsHelper

  def omeka_collections_list(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.title,r)))
    end
    res=content_tag(:tbody, res.join.html_safe)
    content_tag(:table, res, {class: 'table table-striped'})
  end
  
  def omeka_collection_hierarchy(record)
    return [] if record.collection.nil?
    res=[]
    cnt=0
    record.collection.ancestors(true).each do |r|
      cnt+=1
      res << "<ul>"
      res << content_tag(:li, r.title)
    end
    while cnt>0 do
      res << "</ul>"
      cnt -= 1
    end
    content_tag(:div, res.join.html_safe)
  end

  def omeka_collection_show(record)
    res=[]
    res << "Titolo della collezione: #{link_to(record.title, record.omeka_url)}"
    content_tag(:div, res.join.html_safe)
  end

end
