module SpSectionsHelper
  def sp_section_show(record)
    res=[]
    res << content_tag(:p, "Descrizione: #{record.description}") if !record.description.blank?
    res << content_tag(:p, "Scaffale Clavis di provenienza: #{link_to(record.clavis_shelf.shelf_name, record.clavis_shelf.clavis_url)}".html_safe) if !record.clavis_shelf.nil? and !current_user.nil?

    res << content_tag(:ul, sp_section_list_sections(record.sp_sections(!current_user.nil?)))
    res.join.html_safe
  end

  def sp_section_list_sections(sections)
    res=[]
    sections.each do |s|
      nsked=s.sp_items.size
      if nsked==0
        ski=''
      else
        if current_user.nil?
          ski=content_tag(:span, " (#{s.sp_items.size} #{nsked==1 ? 'scheda' : 'schede'})")
        else
          ski=content_tag(:span, " (#{s.sp_items.size} #{nsked==1 ? 'scheda' : 'schede'}, #{s.status_label})")
        end
      end
      if s.sp_sections==[]
        sublist = ''
      else
        sublist = sp_section_list_sections(s.sp_sections(!current_user.nil?))
      end
      res << content_tag(:li,
                         content_tag(:span,
                                     link_to("#{s.title}",
                                             build_link(sp_section_path(s)))) + ski + sublist)
    end
    res.size==0 ? '' : content_tag(:ul, res.join("\n").html_safe, style:'font-size: 120%')
  end

end
