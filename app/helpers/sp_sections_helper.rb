module SpSectionsHelper
  def sp_section_show(record)
    res=[]
    res << content_tag(:p, "Bibliografia: #{record.sp_bibliography.title}")
    res << content_tag(:p, "Sezione: #{record.title}")
    res << content_tag(:p, "Descrizione: #{record.description}") if !record.description.blank?
    res << content_tag(:div, sp_section_list_sections(record.sp_sections))
    res << content_tag(:div, sp_items_list_items(record.sp_items))
    res.join.html_safe
  end

  def sp_section_list_sections(sections)
    res=[]
    sections.each do |s|
      nsked=s.sp_items.size
      if nsked==0
        ski=''
      else
        ski=content_tag(:span, " (#{s.sp_items.size} #{nsked==1 ? 'scheda' : 'schede'})")
      end
      if s.sp_sections==[]
        sublist = ''
      else
        sublist = sp_section_list_sections(s.sp_sections)
      end
      res << content_tag(:li,
                         content_tag(:span,
                                     link_to(s.title,
                                             build_link(sp_section_path(s, :number=>s.number)))) + ski + sublist)
    end
    res.size==0 ? '' : content_tag(:ul, res.join("\n").html_safe)
  end

end
