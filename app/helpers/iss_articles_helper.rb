module IssArticlesHelper

  def iss_journals_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.title, iss_journal_path(r))) +
                              content_tag(:td, r.id))
    end
    content_tag(:table, res.join.html_safe)
  end

  def iss_articles_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.article_title, iss_article_path(r.article_id))) +
                              content_tag(:td, link_to(r.journal_title, iss_journal_path(r.journal_id))) +
                              content_tag(:td, link_to(r.annata, iss_issue_path(r.issue_id))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def iss_pages_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.imagepath, iss_page_path(r.id))) +
                              content_tag(:td, link_to(r.article_title, iss_article_path(r.article_id), style:'font-size:140%' )) +
                              content_tag(:td, link_to(r.journal_title, iss_journal_path(r.journal_id))) +
                              content_tag(:td, link_to(r.annata, iss_issue_path(r.issue_id))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def iss_article_show(record)
    res=[]

    issue=record.issue
    journal=issue.journal
    res << content_tag(:tr, content_tag(:td, 'Titolo') + content_tag(:td, link_to(record.title,iss_article_path(record,format:'pdf')),
                                                                     style:'font-size: 150%'))
    res << content_tag(:tr, content_tag(:td, 'Rivista') + content_tag(:td, link_to(journal.title,iss_journal_path(journal)),
                                                                      style:'font-size: 150%'))
    res << content_tag(:tr, content_tag(:td, 'Fascicolo') + content_tag(:td, iss_issue_show(issue)))
    res << content_tag(:tr, content_tag(:td, 'Pagine') + content_tag(:td, record.pages.size))
    res << content_tag(:tr, content_tag(:td, '') + content_tag(:td, iss_pages_list(record.pages)))

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

  def iss_issue_toc(record)
    res=[]
    record.articles.each do |r|
      res << content_tag(:tr, content_tag(:td, r.id) +
                         content_tag(:td, link_to(r.title, iss_article_path(r.id), remote:true)))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def iss_pages_list(records)
    res=[]
    records.each do |p|
      res << content_tag(:tr, content_tag(:td, link_to("#{p.imagepath}", iss_page_path(p))))
    end
    content_tag(:table, res.join.html_safe, class:'table')    
  end

  def iss_issue_cover_image(record,size=nil)
    page=record.articles.first.pages.first
    image_tag(iss_page_path(page,format:'jpeg',size:size))
  end

  def iss_article_cover_image(record,size=nil)
    page=record.pages.first
    image_tag(iss_page_path(page,format:'jpeg',size:size))
  end

  def iss_article_link_to_pdf(record,size=nil)
    link_to(iss_article_cover_image(record,size), iss_article_path(record, format:'pdf'))
  end

  def iss_page_link_to_pdf(record,size=nil)
    link_to(image_tag(iss_page_path(record, format:'jpeg',size:size)), iss_page_path(record, format:'pdf'))
  end

end
