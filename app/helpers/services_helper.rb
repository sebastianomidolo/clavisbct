# coding: utf-8
module ServicesHelper
  def services_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Nome', class:'col-md-2 text-left') +
                            content_tag(:td, 'Descrizione', class:'col-md-6 text-left') +
                            content_tag(:td, '', class:'col-md-3') +
                            content_tag(:td, '', class:'col-md-3'), class:'success')

    records.each do |r|
      elimina = ''
      # elimina = link_to("Elimina", r, method: :delete, data: { confirm: "Confermi eliminazione della scheda #{r.name}?" }, class:'btn btn-warning') if can? :destroy, Service
      modifica = ''
      modifica = link_to('Modifica', edit_service_path(r), class:'btn btn-success') if can? :edit, Service
      res << content_tag(:tr, content_tag(:td, link_to(r.to_label,r)) +
                              content_tag(:td, r.description) +
                              content_tag(:td, modifica) +
                              content_tag(:td, elimina))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
    
  end

  def services_descendants_index(service)
    # services = Service.find_by_sql("select * from public.view_services order by order_sequence")
    services = service.descendants_index
    res = []
    prec_level = 0
    services.each do |r|
      lvl = prec_level - r.level.to_i
      if r.level.to_i > prec_level
        res << "<ul>" 
        prec_level = r.level.to_i
      else
        while lvl > 0
          res << "</ul>"
          lvl -= 1
        end
        prec_level = r.level.to_i
      end
      spclass = r.visible? ? '' : 'text-muted'
      if r.num_docs.to_i>0
        name = content_tag(:span, "#{r.name} (#{r.num_docs} document#{r.num_docs.to_i==1 ? 'o' : 'i'})", class:"#{spclass}")
      else
        name = content_tag(:span, r.name, class:"#{spclass}")
      end

      next if !can? :manage, Service and !r.visible?

      res << content_tag(:li, "#{link_to(name, service_path(r,current_title_id:params[:current_title_id]))} ".html_safe)

    end
    # content_tag(:ol, res.join.html_safe)
    content_tag(:div, res.join.html_safe)
  end

  def service_roles(service)
    res = []
    service.roles.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.name,role_path(r))))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def role_services(role)
    res = []
    role.servizi.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.to_label,service_path(r))))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')    
  end

  def service_attachments(service,params)
    d_objects = service.attachments.collect {|o| o.d_object}
    d_objects_view(d_objects,params.merge({scale_image:'',context:'service_attachments'}))
  end
  
end


                            

