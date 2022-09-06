# coding: utf-8
module SpBibliographiesHelper

  def sp_bibliographies_index
    res = []
    sql=%Q{select cl.library_id,cl.label,count(b) from clavis.library cl join sp.sp_bibliographies b using(library_id) where cl.library_internal='1' group by cl.library_id order by cl.label}
    SpBibliography.connection.execute(sql).to_a.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['label'], sp_bibliographies_path(library_id:r['library_id']))))
    end
    res << content_tag(:tr, content_tag(:td, link_to("Tutte le bibliografie", sp_bibliographies_path)))
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def sp_bibliographies_orig_link(b)
    link_to(b.orig_id, "http://biblio.comune.torino.it/ProgettiCivica/SenzaParola/typo.cgi?id=#{b.orig_id}")
  end

  def sp_bibliography_clavis_shelf_titles(shelf_id)
    res = []
    ClavisManifestation.in_shelf(shelf_id).each do |r|
      res << content_tag(:tr, content_tag(:td, r.title))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sp_bibliographies_list_old(records)
    res=[]
    records.each do |r|
      # next if r.description.blank?
      res << render(:partial=>'/sp_bibliographies/shortview', :locals=>{:bibliography=>r})
    end
    res.join.html_safe
  end

  def sp_bibliographies_list(records,user=nil)
    res=[]
    if user.nil?
      records.each do |r|
        # res << content_tag(:tr, content_tag(:td, r.status) + content_tag(:td, link_to(r.title, sp_bibliography_path(r))))
        res << content_tag(:tr, content_tag(:td, link_to(r.title, sp_bibliography_path(r))))
      end
    else
      records.each do |r|
        res << content_tag(:tr, content_tag(:td, check_box_tag('managed_bib', r.id, false, :onchange=>'submit()')) +
                                content_tag(:td, link_to(r.title, sp_bibliography_path(r))))
      end
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end


  def sp_bibliography_show(record)
    res=[]
    res << content_tag(:h1, record.title)
    res << content_tag(:h2, record.subtitle)
    # res << sp_bibliography_short_description(record)
    res << SpBibliography.sanifica_html(record.html_description)
    res.join.html_safe
  end

  def sp_bibliography_cover_image(record)
    image_tag("https://#{request.host_with_port}#{cover_image_sp_bibliography_path(record)}") if !record.cover_image.nil?
  end

  def sp_bibliography_short_description(record)
    return '' if record.html_description.blank?
    res=SpBibliography.sanifica_html(record.html_description)

    i=res.index('<br')
    i = (i.nil? or i>100) ? 100 : i-1
    if res.length > 100
      add=' [...]'
    else
      add=''
    end
    content_tag(:div, "#{res[0..i]}#{add}".html_safe)
    # content_tag(:div, res.html_safe)
  end

  def sp_users_list
    res = []
    res << content_tag(:tr, content_tag(:td, 'Nome utente') +
                            content_tag(:td, 'Numero di bibliografie'))
    SpUser.enabled_users.each do |r|
      lnk = link_to("#{r.name} <b>#{r.lastname}</b>".html_safe, users_sp_bibliographies_path(user_id:r.id))
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.bibliographies_count))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sp_bibliography_check_items(record)
    res=[]
    record.sp_items.each do |i|
      begin
        cm=i.clavis_manifestation
      rescue
        cm_id="errore: #{i.id}"
      end
      if cm.nil?
        clavis_collciv=''
        clavis_colldec=''
        clavis_sigle=''
      else
        cm_id = cm.id
        info=cm.collocazioni_e_siglebib_per_senzaparola
        clavis_collciv=info['collciv']
        clavis_colldec=info['colldec']
        clavis_sigle=info['sigle']
        i.colldec.gsub!(' ', '.') if !i.colldec.blank?
        i.collciv.gsub!(' ', '.') if !i.collciv.blank?
        collciv_color = i.collciv!=clavis_collciv ? 'cyan' : 'white'
        colldec_color = i.colldec!=clavis_colldec ? 'cyan' : 'white'
        sigle_color = i.sigle!=clavis_sigle ? 'cyan' : 'white'
      end
      res << content_tag(:tr, content_tag(:td, cm_id) +
                         content_tag(:td, link_to(i.bibdescr[0..20], SpItem.senza_parola_item_path(i.item_id, i.bibliography_id))) +
                         content_tag(:td, "#{i.collciv}<br/><span style='background-color:#{collciv_color}'>#{clavis_collciv}</span>".html_safe) +
                         content_tag(:td, "#{i.colldec}<br/><span style='background-color:#{colldec_color}'>#{clavis_colldec}</span>".html_safe) +
                         content_tag(:td, "#{i.sigle}<br/><span style='background-color:#{sigle_color}'>#{clavis_sigle}</span>".html_safe))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sp_redir_page(sp_items)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Bibliografia') +
                            content_tag(:td, 'Sezione'), class:'success')
    sp_items.each do |r|
      next if !r.published?
      bib_link = link_to(r.sp_bibliography.to_label, r.sp_bibliography)
      section_link = r.sp_section.nil? ? '-' : link_to(r.sp_section.to_label, r.sp_section)
      res << content_tag(:tr, content_tag(:td, bib_link) +
                              content_tag(:td, section_link))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')    
  end

  def sp_bibliographies_breadcrumbs
    # return params.inspect
    # return @sp_section.homepage
    links=[]
    if user_signed_in?
      links << link_to('Bibliografie', sp_bibliographies_path)
    else
      if @sp_bibliography.homepage.blank? and @sp_section.blank?
        links << link_to('Bibliografie', 'https://bct.comune.torino.it/bibliografie')
        links << link_to('Elenco', sp_bibliographies_path)
      else
        if @sp_section.homepage.blank?
          if @sp_bibliography.homepage.blank?
            linktext = ''
            # return linktext
          else
            linktext,url = @sp_bibliography.homepage.split(' | ')
          end
        else
          linktext,url = @sp_section.homepage.split(' | ')
        end
        links << link_to(linktext,url) if ! linktext.blank?
      end
    end
    if params[:controller]=='sp_bibliographies' and ['show','edit'].include?(params[:action])
      # links << link_to(@sp_bibliography.title, sp_bibliography_path)
      if user_signed_in?
        links << link_to(@sp_bibliography.title, sp_bibliography_path) if !@sp_section.nil? and @sp_section.homepage.blank?
      end
    end
    if params[:controller]=='sp_bibliographies' and ['users'].include?(params[:action])
      links << link_to('Amministrazione', admin_sp_bibliographies_path)
      links << link_to('Utenti', users_sp_bibliographies_path)
      links << @user.email if !@user.nil?
    end
    if ['sp_items','sp_sections'].include?(params[:controller]) and ['edit','show','new'].include?(params[:action])
      if user_signed_in?
        links << link_to(@sp_bibliography.title, sp_bibliography_path(@sp_bibliography.id))
      else
        links << link_to(@sp_bibliography.title, sp_bibliography_path(@sp_bibliography.id)) if @sp_section.homepage.blank?
      end
      if !@sp_section.nil? and !@sp_section.number.nil?
        section=@sp_section
        bc=[]
        while section.parent>0
          bc << link_to("#{section.parent_section.title}", sp_section_path(section.parent_section))
          section = section.parent_section
        end
        section = @sp_section
        links << bc.reverse if bc.size>0
        links << link_to("#{section.title}", sp_section_path(section)) if !section.title.nil?
      end
      links << link_to(@sp_item.to_label, sp_item_path(@sp_item)) if !params[:d_object].nil?
    end

    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

end


