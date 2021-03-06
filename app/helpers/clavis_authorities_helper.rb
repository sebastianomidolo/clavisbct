module ClavisAuthoritiesHelper
  def clavis_authorities_list(records)
    res=[]
    records.each do |r|
      lnk=link_to(r.full_text, r.clavis_url(:edit), :target=>'_blank')
      res << content_tag(:tr, content_tag(:td, lnk, class:'col-md-4') +
                         content_tag(:td, r.bid, class:'col-md-2') + content_tag(:td, r.authority_type))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end
end
