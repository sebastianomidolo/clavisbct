# coding: utf-8
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


  def clavis_loans_view(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Titolo') +
                       content_tag(:td, 'Stato') +
                       content_tag(:td, 'Inizio') +
                       content_tag(:td, 'Giorni') +
                       content_tag(:td, 'Rinnovi') +
                       content_tag(:td, 'Restituito il'))
    records.each do |r|
      if r.manifestation_id!=0
        m_lnk=link_to(r.title, ClavisManifestation.clavis_url(r.manifestation_id, :opac))
      else
        m_lnk="#{r.title} [fuori catalogo]"
      end
      d_rest = r.loan_date_end.nil? ? '' : r.loan_date_end.to_date
      res << content_tag(:tr, content_tag(:td, m_lnk) +
                         content_tag(:td, r.loan_status_label.sub(' ', '&nbsp;').html_safe) +
                         content_tag(:td, r.loan_date_begin.to_date) +
                         content_tag(:td, r.giorni) +
                         content_tag(:td, r.renew_count) +
                         content_tag(:td, d_rest))
                         
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def clavis_loans_view_by_month(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Anno/Mese') +
                            content_tag(:td, 'Numero prestiti'))
    hash=records.group_by {|x| x.loan_date_begin.strftime("%Y/%m")}
    hash.keys.sort.each do |r|
      res << content_tag(:tr, content_tag(:td, r) +
                              content_tag(:td, hash[r].count))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def clavis_loans_view_by_gender(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Genere') +
                            content_tag(:td, 'Numero prestiti'))
    hash=records.group_by {|x| x.gender}
    hash.keys.sort.each do |r|
      res << content_tag(:tr, content_tag(:td, r) +
                              content_tag(:td, hash[r].count))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def clavis_loans_view_by_citizenship(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Cittadinanza') +
                            content_tag(:td, 'Numero prestiti'))
    hash=records.group_by {|x| x.citizenship.nil? ? '?' : x.citizenship.downcase.strip}
    hash.keys.sort.each do |r|
      res << content_tag(:tr, content_tag(:td, r) +
                              content_tag(:td, hash[r].count))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end


end
