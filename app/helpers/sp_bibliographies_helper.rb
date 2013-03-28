module SpBibliographiesHelper
  def sp_bibliographies_list_old(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.title, build_link(sp_bibliography_path(r)))) +
                         content_tag(:td, r.status))
    end
    content_tag(:table, res.join.html_safe)
  end


  def sp_bibliographies_list(records)
    res=[]
    records.each do |r|
      next if r.description.blank?
      res << render(:partial=>'/sp_bibliographies/shortview', :locals=>{:bibliography=>r})
    end
    res.join.html_safe
  end

  def sp_bibliography_show(record)
    res=[]
    res << content_tag(:h1, record.title)
    res << content_tag(:h2, record.subtitle)
    res << content_tag(:p, record.description_html.html_safe)
    res.join.html_safe
  end

end
