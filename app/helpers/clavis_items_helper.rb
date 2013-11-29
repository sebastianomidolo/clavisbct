module ClavisItemsHelper
  def clavis_item_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe)
  end

  def clavis_items_shortlist(records, table_id='items_list')
    return '' if records.size==0
    res=[]
    # Eventuale link a qualcosa:
    # content_tag(:td, link_to('[presta]', r.clavis_url(:loan), :target=>'_blank'))
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r.collocazione) +
                         content_tag(:td, r.item_media_type) +
                         content_tag(:td, link_to(r.title, r.clavis_url(:show), :target=>'_blank')) +
                         content_tag(:td, r.inventario),
                         {:data_view=>r.view})
    end
    res << content_tag(:div, "Trovati #{records.total_entries} esemplari", class: 'panel-heading')
    res=content_tag(:table, res.join.html_safe, {:id=>table_id, class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

end
