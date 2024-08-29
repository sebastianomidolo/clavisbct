# coding: utf-8
module ServiceDocsHelper
  def service_docs_list(records,service=nil)
    res = []

    if service.nil?
      res << content_tag(:tr, content_tag(:td, 'Servizio', class:'col-md-3 text-left') +
                              content_tag(:td, 'Titolo', class:'col-md-3 text-left') +
                              content_tag(:td, 'Tipo documentazione', class:'col-md-4 text-left'), class:'success')
      records.each do |r|
        title = r.title.blank? ? 'senza titolo' : r.title
        res << content_tag(:tr, content_tag(:td, link_to(r.service_name, service_path(r.service_id))) +
                                content_tag(:td, link_to(title, service_doc_path(r))) + 
                                content_tag(:td, r.service_doc_type.to_label))
      end
    else
      res << content_tag(:tr, content_tag(:td, 'Titolo del documento', class:'col-md-3 text-left') +
                              content_tag(:td, 'Tipo documentazione', class:'col-md-4 text-left'), class:'success')
      records.each do |r|
        title = r.title.blank? ? 'senza titolo' : r.title
        res << content_tag(:tr, content_tag(:td, link_to(title, service_doc_path(r))) + 
                                content_tag(:td, r.service_doc_type.to_label))
      end
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
    
  end

  def service_doc_attachments(service_doc,params)
    d_objects = service_doc.attachments.collect {|o| o.d_object}
    d_objects_view(d_objects,params.merge({scale_image:'',context:'service_doc_attachments'}))
  end

end
