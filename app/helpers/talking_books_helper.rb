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
    if !record.clavis_item.nil?
      lnk=clavis_item_path(record.clavis_item)
      res << link_to('Vedi esemplare in Clavis',lnk)
    else
      res << "Non trovato su Clavis"
    end
    res
  end

end
