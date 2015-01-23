module ContainersHelper
  def containers_cloud(current_record)
    res=[]
    Container.all(:order=>"regexp_replace(label,'([A-Z]+)','')::integer").each do |c|
      if c==current_record
        res << content_tag(:button, c.label, class: 'btn btn-default')
      else
        # res << content_tag(:button, link_to(c.label,c), class: 'btn btn-primary')
        res << link_to(c.label,c, class: 'btn btn-success')
      end
      end
    res.join.html_safe
  end

  def container_show(record)
    res=[]
    prec_mid=nil
    prec_item=nil
    prec_cons=nil
    cnt=0
    record.container_items.each do |i|
      cnt += 1
      inventario=nil
      if i.manifestation_id!=prec_mid
        mtitle=i.manifestation_id == 0 ? '[fuori catalogo]' : i.clavis_manifestation.title
        lnk_opac=link_to(mtitle, clavis_manifestation_path(i.manifestation_id), target: '_blank')
      else
        lnk_opac = i.item_title
      end
      if i.item_id!=prec_item and !i.clavis_item.nil?
        google_drive_link=link_to(i.row_number,i.google_drive_url)
        if i.item_id.nil?
          lnk_item = ''
        else
          lnk_item = link_to(i.collocazione, i.clavis_item.clavis_url, target: '_blank')
          inventario = i.clavis_item.inventario
        end
      else
        lnk_item = ''
        inventario=''
        google_drive_link=''
      end
      if i.consistency_note_id!=prec_cons
        lnk_consistenza = i.consistency_note_id.nil? ? '' : link_to('[Periodico]', clavis_consistency_note_path(i.consistency_note_id), target: '_blank')
      else
      end

      prec_mid=i.manifestation_id
      prec_item=i.item_id
      prec_cons=i.consistency_note_id

      res << content_tag(:tr,
                         content_tag(:td, cnt) +
                         content_tag(:td, lnk_item) +
                         content_tag(:td, lnk_opac) +
                         content_tag(:td, inventario) +
                         content_tag(:td, google_drive_link) +
                         content_tag(:td, lnk_consistenza))
    end
    res=content_tag(:table, res.join.html_safe, :class=>'table')
  end
end

