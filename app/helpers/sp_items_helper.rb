module SpItemsHelper
  def sp_item_show(record)
    res=[]
    res << content_tag(:p, record.bibdescr)
    res << content_tag(:p, "Collocazione: #{record.collocazioni}")
    res << content_tag(:p, "Bibliografia: #{record.sp_bibliography.title}")
    res << content_tag(:p, "Sezione della bibliografia: #{record.thesection}")

    res.join.html_safe
  end
end
