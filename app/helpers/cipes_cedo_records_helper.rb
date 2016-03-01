module CipesCedoRecordsHelper
  def cipes_cedo_record_list(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r[:titolo], r.cedo_url) +
                                          "<br/><em>#{r.abstract}</em>".html_safe) +
                         content_tag(:td, r[:annoed])
                         )
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end
end
