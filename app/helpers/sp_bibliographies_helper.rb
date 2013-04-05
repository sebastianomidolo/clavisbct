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
    # res << sp_bibliography_short_description(record)
    res << SpBibliography.sanifica_html(record.html_description)
    res.join.html_safe
  end

  def sp_bibliography_short_description(record)
    return '' if record.html_description.blank?
    res=SpBibliography.sanifica_html(record.html_description)
    i=res.index('<br')
    i = (i.nil? or i>300) ? 300 : i-1
    content_tag(:div, res[0..i].html_safe)
  end

end
