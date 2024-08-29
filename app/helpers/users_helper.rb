module UsersHelper

  def users_list(users)
    res = []
    res << content_tag(:tr, content_tag(:td, link_to('UserId', users_path(order:'id',direction:params[:direction])), class:'col-md-1 text-left') +
                            content_tag(:td, link_to('ClavisId', users_path(order:'librarian_id',direction:params[:direction])), class:'col-md-1 text-left') +
                            content_tag(:td, link_to('UserName', users_path(order:'email',direction:params[:direction])), class:'col-md-2 text-left') +
                            content_tag(:td, link_to('Biblioteca', users_path(order:'siglabib',direction:params[:direction])), class:'col-md-1 text-left') +
                            content_tag(:td, link_to('Cognome', users_path(order:'lastname',direction:params[:direction])), class:'col-md-1 text-left') +
                            content_tag(:td, link_to('SignInCount', users_path(order:'sign_in_count',direction:params[:direction])), class:'col-md-1 text-left') +
                            content_tag(:td, link_to('LastSignInAt', users_path(order:'last_sign_in_at',direction:params[:direction])), class:'col-md-2 text-left'), class:'2success')

    users.each do |r|
      clavislnk = r.librarian_id.nil? ? '-' : link_to(r.librarian_id, ClavisLibrarian.clavis_url(r.librarian_id), class:'btn btn-success', title:'Vedi in ClavisNG')
      lnk = link_to(content_tag(:span, r.id,class:'btn btn-info'), user_path(r), title:'Vedi in ClavisBct')
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, clavislnk) +
                              content_tag(:td, r.email) +
                              content_tag(:td, r.siglabib) +
                              content_tag(:td, r.lastname) +
                              content_tag(:td, r.sign_in_count) +
                              content_tag(:td, r.last_sign_in_at))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def user_roles(user, read_only=false)
    res = []
    user.roles.each do |r|
      if read_only==false
        res << content_tag(:tr, content_tag(:td, link_to(r.name,role_path(r))))
      else
        res << content_tag(:tr, content_tag(:td, r.name))
      end
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')    
  end

  def role_users(role)
    res = []
    role.users.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.email,user_path(r))))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')    
  end

  def roles_list(roles)
    res = []
    roles.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.name, role_path(r))) +
                              content_tag(:td, r.usernames))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')    
  end

  def user_list_of(users)
    res = []
    users.each do |u|
      res << content_tag(:tr, content_tag(:td, link_to(u.email, user_path(u))))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

end
