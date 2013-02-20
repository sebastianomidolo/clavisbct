# lastmod 20 febbraio 2013

module ClavisManifestationHelper
  def clavis_manifestation_view(record)
    config = Rails.configuration.database_configuration
    r=[]
    # lnk=content_tag(link_to(record.title, record.clavis_url))
    lnk=link_to(record.title, record.clavis_url)
    r << content_tag(:div, content_tag(:b, lnk))
    r << content_tag(:div, clavis_issue_list(record))
    r.join.html_safe
  end
end
