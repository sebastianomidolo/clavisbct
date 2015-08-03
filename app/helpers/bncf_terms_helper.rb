module BncfTermsHelper

  def bncf_terms_links(records)
    res=[]
    records.each do |r|
      if r.bncf_id.nil?
        id=r.parent_term.bncf_id
        spec=" [#{r.termtype}]"
        text=r.parent_term.term
      else
        spec=""
        id=r.bncf_id
        text=r.term
      end
      res << content_tag(:span, link_to("<b>#{text}</b> (#{r.category})".html_safe, "http://thes.bncf.firenze.sbn.it/termine.php?id=#{id}"))
      res << content_tag(:div, r.definition) if !r.definition.nil?
    end
    res.join.html_safe
  end

  def bncf_term_show(record)
    res=[]
    res << content_tag(:div, record.termtype, class:'col-md-2')
    if record.parent_term.nil?
      res << content_tag(:div, content_tag(:span, link_to("<b>#{record.term}</b>".html_safe, BncfTerm.url(record.bncf_id))), class:'col-md-2 text-success')
    else
      res << content_tag(:div, content_tag(:span, link_to("<b>#{record.parent_term.term}</b>".html_safe, "http://thes.bncf.firenze.sbn.it/termine.php?id=#{record.parent_term.bncf_id}")), class:'col-md-2 text-success')
    end
    res << content_tag(:div, record.category, class:'col-md-3 text-warning')
    res << content_tag(:div, record.definition, class:'col-md-5 text-danger')
    content_tag(:div, res.join.html_safe, class: 'row')
  end

  def bncf_terms_obsolete_terms(records)
    res=[]
    res << content_tag(:tr, content_tag(:th, 'Clavis') +
                       content_tag(:th,'Nuovo soggettario'));

    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['non_preferito'], ClavisAuthority.clavis_url(r['authority_id'])),
                                          :target=>'_new') +
                         content_tag(:td, link_to(r['preferito'], BncfTerm.url(r['bncf_id']), :target=>'_new')))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def bncf_terms_missing_terms(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r['subject_class']) +
                         content_tag(:td, link_to(r['heading'], ClavisAuthority.clavis_url(r['authority_id'])),
                                          :target=>'_new') +
                         content_tag(:td, link_to("Soggetto #{r['subject_id']}", ClavisAuthority.clavis_url(r['subject_id'])),
                                          :target=>'_new'))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

end
