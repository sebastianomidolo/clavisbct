module ClavisLoansHelper
  def clavis_loans_list(records)
    res=[]
    records.each do |r|
      if r.manifestation_id!=0
        m_lnk=link_to(r.title, clavis_manifestation_path(r.manifestation_id, :redir=>true))
      else
        m_lnk="#{r.title} [fuori catalogo]"
      end
      i_lnk=link_to(r.collocazione, clavis_item_path(r.item_id, :redir=>true))
      res << content_tag(:tr, content_tag(:td, i_lnk) +
                         content_tag(:td, m_lnk))
                         
    end
    content_tag(:table, res.join.html_safe)
  end
end
