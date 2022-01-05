module ClavisAuthoritiesHelper

  def clavis_authorities_list(records)
    res=[]
    records.each do |r|
      lnk=link_to(r.full_text, r.clavis_url(:show), :target=>'_blank')
      lnk2=link_to("[edit]", r.clavis_url(:edit), :target=>'_blank')
      res << content_tag(:tr, content_tag(:td, lnk2, class:'col-md-1') +
                         content_tag(:td, lnk, class:'col-md-3') +
                         content_tag(:td, r.bid, class:'col-md-2') + content_tag(:td, r.authority_type))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def clavis_authorities_dupl(records)
    res=[]
    records.each do |r|
      links=[]
      r.ids.gsub(/\{|\}/,'').split(',').each do |id|
        links << link_to(id, ClavisAuthority.clavis_url(id,:show), :target=>'_blank')
      end
      res << content_tag(:tr, content_tag(:td, r.count, class:'col-md-1') +
                              content_tag(:td, r.heading, class:'col-md-3') +
                              content_tag(:td, links.join("<br/>").html_safe, class:'col-md-9'))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

end
