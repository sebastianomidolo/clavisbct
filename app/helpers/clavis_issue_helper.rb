# lastmod 20 febbraio 2013

module ClavisIssueHelper
  def clavis_issue_list(manifestation)
    r=[]
    manifestation.ultimi_fascicoli.each do |i|
      r << content_tag(:tr, content_tag(:td, i.issue_number) +
                       content_tag(:td, i.issue_year))
    end
    content_tag(:table, r.join.html_safe)
  end
end
