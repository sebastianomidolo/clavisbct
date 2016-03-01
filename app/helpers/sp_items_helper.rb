module SpItemsHelper
  def sp_item_show(record)
    res=[]
    style="margin-left: 20px"
    res << content_tag(:p, record.bibdescr.html_safe)
    res << content_tag(:p, "Collocazione: #{record.collocazioni}") if !record.collocazioni.blank?
    res << content_tag(:div,
                       content_tag(:span, "Bibliografia di riferimento: ", :style=>style) + 
                       content_tag(:span,
                                   link_to(record.sp_bibliography.title,
                                           build_link(sp_bibliography_path(record.sp_bibliography.id)))))

    if !record.thesection.blank?
      res << content_tag(:div,
                         content_tag(:span, "Sezione della bibliografia: ", :style=>style) + 
                         content_tag(:span,
                                     link_to(record.thesection,
                                             build_link(sp_section_path(record.sp_section,
                                                                        :number=>record.sp_section.number)))))
    end


    res.join.html_safe
  end

  def sp_items_list_items(sp_items)
    res=[]
    sp_items.each do |i|
      res << content_tag(:tr, content_tag(:td,
                                          link_to(i.bibdescr,
                                                  build_link(sp_item_path(i)))) +
                         content_tag(:td, i.collciv))
    end
    content_tag(:table, res.join.html_safe)
  end

  def sp_items_ricollocati_a_scaffale_aperto(sp_items)
    res=[]
    sp_items.each do |i|
      res << content_tag(:tr, content_tag(:td,
                                          link_to(i.bibdescr, i.senza_parola_item_path,target:'_new'),
                                          style:'width:50%') +
                         content_tag(:td, i.ex_collocazione) +
                         content_tag(:td, i.section) +
                         content_tag(:td, i.collocation) +
                         content_tag(:td, i.bibliography_title))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end


end
