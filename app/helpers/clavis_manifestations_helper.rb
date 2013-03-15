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
      tit=r.title.blank? ? '[vedi titolo]' : r.title[0..80]
      res << content_tag(:tr, content_tag(:td, r.thebid) +
                         content_tag(:td, r.bib_level) +
                         content_tag(:td, r.bib_type) +
                         content_tag(:td, link_to('[edit]', r.clavis_url(:edit))) +
                         content_tag(:td, link_to(tit, r.clavis_url)))
    end
    content_tag(:table, res.join.html_safe)
  end


  def clavis_manifestations_perbid
    sql="select bid_source,count(*) from clavis.manifestation where bib_level in('m','c','s') group by bid_source order by bid_source;"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      txt=r['bid_source'].blank? ? '?' : r['bid_source']
      res << content_tag(:tr, content_tag(:td, r['count']) +
                         content_tag(:td, txt) +
                         content_tag(:td, link_to('collane', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'c'))) +
                         content_tag(:td, link_to('monografie', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'m'))) +
                         content_tag(:td, link_to('seriali', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'s'))) +
                         content_tag(:td, link_to('tutto', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source']))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestations_oggbibl
    sql="select value_key,value_label,value_class from clavis.lookup_value where value_language='it_IT' AND value_class ~* '^OGGBIBL_' order by value_key"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      res << content_tag(:tr, content_tag(:td, r['value_key']) +
                         content_tag(:td, r['value_label']) +
                         content_tag(:td, r['value_class']))
    end
    content_tag(:table, res.join.html_safe)
  end


end
