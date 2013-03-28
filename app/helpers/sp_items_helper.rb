module SpItemsHelper
  def sp_item_show(record)
    res=[]
    res << content_tag(:p, record.bibdescr)
    res << content_tag(:p, "Collocazione: #{record.collocazioni}")
    res << content_tag(:p, "Bibliografia: #{record.sp_bibliography.title}")
    res << content_tag(:p, "Sezione della bibliografia: #{record.thesection}")

    res.join.html_safe
  end

  def sp_items_list_items(sp_items)
    res=[]
    sp_items.each do |i|
      res << content_tag(:tr, content_tag(:td,
                                          link_to(i.bibdescr,
                                                  build_link(sp_item_path(i)))) +
                         content_tag(:td, i.section_number) +
                         content_tag(:td, i.collciv))
    end
    content_tag(:table, res.join.html_safe)
  end


end
