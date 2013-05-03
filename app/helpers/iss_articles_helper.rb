module IssArticlesHelper
  def iss_articles_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.title, iss_article_path(r))) +
                         content_tag(:td, r.id))
    end
    content_tag(:table, res.join.html_safe)
  end

  def iss_article_show(record)
    res=[]

    res << content_tag(:tr, content_tag(:td, 'Titolo') + content_tag(:td, record.title))
    res << content_tag(:tr, content_tag(:td, 'Rivista') + content_tag(:td, record.issue.journal.title))
    res << content_tag(:tr, content_tag(:td, 'Fascicolo') + content_tag(:td, iss_issue_show(record.issue)))
    res << content_tag(:tr, content_tag(:td, 'Pagine') + content_tag(:td, iss_pages_show(record)))

    res=content_tag(:table, res.join.html_safe)
    res
  end

  def iss_issue_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank? or ['id','journal_id','position'].include?(k)
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe)
    res
  end

  def iss_pages_show(record)
    record.pages.size
  end

end
