module SpBibliographiesHelper
  def sp_bibliographies_list(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.title, sp_bibliography_path(r))) +
                         content_tag(:td, r.status))
    end
    content_tag(:table, res.join.html_safe)
  end

  def sp_bibliography_show(record)
    res=[]
    res << content_tag(:h1, record.title)
    res << content_tag(:h2, record.subtitle)
    res << content_tag(:p, record.description)
    res.join.html_safe
  end

end
