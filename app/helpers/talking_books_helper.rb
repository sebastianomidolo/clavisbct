module TalkingBooksHelper
  def talking_books_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.titolo, talking_book_path(r))) +
                         content_tag(:td, r.n))
    end
    content_tag(:table, res.join.html_safe)
  end

  def talking_book_show(record)
    res=[]

    record.attributes.keys.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe)
    record.clavis_manifestations.each do |cm|
      lnk=clavis_manifestation_path(cm)
      res << link_to("Vedi manifestation #{cm.id}",lnk)
      res << content_tag(:div, clavis_manifestation_opac_preview(cm))
    end
    res
  end

  def talking_book_extra_data(record)
    res=[]

    fields=[
            :intestatio,
            :abstract
           ]

    fields.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe)
    res
  end


end
