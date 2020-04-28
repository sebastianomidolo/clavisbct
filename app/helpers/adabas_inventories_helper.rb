
module AdabasInventoriesHelper
  def adabas_inventory_show(record)
    res=[]

    record.attributes.keys.each do |k|
      next if record[k].blank?
      case k
      when 'id'
        next
      when 'bid'
      # txt = 'bid'
        txt = link_to(record[k],adabas_inventories_path(qs:record[k]))
      when 'library_id'
        library=record.clavis_library
        txt = library.label
      else
        txt = record[k]
      end
      res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, txt))
    end
    res=content_tag(:table, res.join.html_safe)
  end

  def adabas_inventory_list(records)
    res=[]
    records.each do |r|
      link_bid = link_to(r.bid,adabas_inventories_path(qs:r.bid))
      res << content_tag(:tr, content_tag(:td, link_to("#{r.serie}-#{r.inv}",adabas_inventory_path(r),remote:true, class:'btn btn-success'), class:'col-md-2') +
                              content_tag(:td, link_bid, class:'col-md-1') +
                              content_tag(:td, r.isbd, class:'col-md-9'))
      res << content_tag(:tr, content_tag(:td, ''), :id=>"item_#{r.id}")
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end
end
