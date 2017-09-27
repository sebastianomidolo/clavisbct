module ExtraCardsHelper
  def extra_cards_shortlist(records)
    res=[]
    records.each do |r|
      lnk=link_to(r.collocazione, extra_card_path(r))
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.serieinv, style:'white-space:nowrap') +
                              content_tag(:td, r.titolo) +
                              content_tag(:td, r.note_interne))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end
  def extra_card_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      case k
      when 'collocation'
      else
        txt = record[k]
      end
      res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, txt))
    end
    res=content_tag(:table, res.join.html_safe)

  end
end
