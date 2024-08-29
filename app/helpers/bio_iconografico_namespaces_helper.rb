module BioIconograficoNamespacesHelper

  def bio_iconografico_namespaces_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Nome', class:'col-md-3') +
                            content_tag(:td, 'Descrizione', class:'col-md-7') +
                            content_tag(:td, 'Accesso', class:'col-md-1') +
                            content_tag(:td, 'Stato', class:'col-md-1'), class:'success')
    records.each do |r|
      lnk = link_to(r.label, bio_iconografico_cards_path(namespace:r.label))
      
      res << content_tag(:tr, content_tag(:td, link_to(r.title, bio_iconografico_namespace_path(r))) +
                              content_tag(:td, r.descr) +
                              content_tag(:td, lnk) +
                              content_tag(:td, r.published? ? link_to("Pubblicato", bctcards_path(namespace:r), class:'btn btn-info') : '-'))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def bio_iconografico_users(record)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Login', class:'col-md-1') +
                            content_tag(:td, 'Nome', class:'col-md-1') +
                            content_tag(:td, 'UserId', class:'col-md-1') +
                            content_tag(:td, 'Stato', class:'col-md-1'), class:'success')
    record.users.each do |r|
      del_link = link_to("Elimina",bio_iconografico_namespace_path(user_id:r.id), method: :delete, data: { confirm: "Confermi cancellazione #{r.email}?" })
      roles=User.find(r.id).roles.collect {|i| i.name if i.name.match(/^BioIco/)}.compact.join(', ')
      res << content_tag(:tr, content_tag(:td, r.email) +
                              content_tag(:td, "#{r.name} #{r.lastname} (#{roles})") +
                              content_tag(:td, r.id) +
                              content_tag(:td, del_link.html_safe))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  
end
