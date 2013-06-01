# lastmod 20 febbraio 2013

module ClavisManifestationsHelper
  def clavis_manifestation_view(record)
    config = Rails.configuration.database_configuration
    r=[]
    # lnk=content_tag(link_to(record.title, record.clavis_url))
    lnk=link_to(record.title, record.clavis_url(:opac))
    r << content_tag(:div, content_tag(:b, lnk))
    r << content_tag(:div, clavis_issue_list(record))
    r.join.html_safe
  end

  def clavis_manifestation_opac_preview(record)
    %Q{<iframe src="http://bct.comperio.it/opac/detail/badge/sbct:catalog:#{record.id}?height=300&showabstract=1&coversize=normal" frameborder="0" width="600" height="300"></iframe>}.html_safe
  end

  def clavis_manifestations_shortlist(records)
    res=[]
    records.each do |r|
      tit=r.title.blank? ? '[vedi titolo]' : r.title[0..80]
      res << content_tag(:tr, content_tag(:td, r.thebid) +
                         content_tag(:td, r.bib_level) +
                         content_tag(:td, r.bib_type) +
                         content_tag(:td, r.created_by) +
                         content_tag(:td, link_to('[opac]', r.clavis_url(:opac), :target=>'_blank')) +
                         content_tag(:td, link_to('[edit]', r.clavis_url(:edit), :target=>'_blank')) +
                         content_tag(:td, link_to(tit, r.clavis_url, :target=>'_blank')))
    end
    content_tag(:table, res.join.html_safe)
  end


  def clavis_manifestations_perbid
    sql="select bid_source,count(*) from clavis.manifestation where bib_level in('m','c','s') group by bid_source order by bid_source;"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      if r['bid_source'].blank?
        r['bid_source']='null'
        txt='[missing]'
      else
        txt=r['bid_source']
      end
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
      # http://clavisbct.selfip.net/clavis_manifestations/shortlist?bib_type=a02
      res << content_tag(:tr, content_tag(:td, r['value_key']) +
                         content_tag(:td, link_to(r['value_label'], shortlist_clavis_manifestations_url(:bib_type=>r['value_key']))) +
                         content_tag(:td, link_to("#{r['value_key']} (senza bid)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'null'))) +
                         content_tag(:td, link_to("#{r['value_key']} (LOC)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'LOC'))) +
                         content_tag(:td, link_to("#{r['value_key']} (UKLIB)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'UKLIB'))) +
                         content_tag(:td, link_to("#{r['value_key']} (FRLIB)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'FRLIB'))))
    end
    content_tag(:table, res.join.html_safe)
  end


end
