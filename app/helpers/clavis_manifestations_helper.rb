# lastmod 20 febbraio 2013

module ClavisManifestationsHelper
  def clavis_manifestation_view(record)
    config = Rails.configuration.database_configuration
    r=[]
    # lnk=content_tag(link_to(record.title, record.clavis_url))
    lnk=link_to(record.title, record.clavis_url)
    r << content_tag(:div, content_tag(:b, lnk))
    r << content_tag(:div, clavis_issue_list(record))
    r.join.html_safe
  end

  def clavis_manifestations_shortlist(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r.thebid) +
                         content_tag(:td, r.title))
    end
    content_tag(:table, res.join.html_safe)
  end


  def clavis_manifestations_perbid
    sql="select bid_source,count(*) from clavis.manifestation group by bid_source order by bid_source;"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['bid_source'], shortlist_clavis_manifestations_url(:bid_source=>r['bid_source']))))
    end
    content_tag(:table, res.join.html_safe)
  end

end
