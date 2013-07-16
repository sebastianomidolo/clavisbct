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
    res=[]
    # Eventuale link a qualcosa:
    # content_tag(:td, link_to('[presta]', r.clavis_url(:loan), :target=>'_blank'))
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r.view),
                         {:data_view=>r.view})
    end
    content_tag(:table, res.join.html_safe, {:id=>table_id})
  end

end
