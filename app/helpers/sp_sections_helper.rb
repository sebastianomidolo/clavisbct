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
      res << content_tag(:tr,
                         content_tag(:td, link_to(s.title,
                                                  build_link(sp_section_path(s, :number=>s.number)))) +
                         content_tag(:td, s.parent))
    end
    res.size==0 ? '' : content_tag(:table, res.join("\n").html_safe)
  end

end
