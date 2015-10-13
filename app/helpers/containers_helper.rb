# -*- coding: utf-8 -*-
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
        if i.manifestation_id!=0
          lnk_opac="#{link_to(i.clavis_item.title, ClavisManifestation.clavis_url(i.manifestation_id,:opac), target: '_blank')} #{link_to('<b>[edit]</b>'.html_safe, ClavisItem.clavis_url(i.item_id,:show), target: '_blank')}"
          # lnk_opac='x'
        else
          lnk_opac = i.clavis_item.title
        end
      else
        lnk_opac = '-'
      end
      if user_signed_in?
        bip=best_in_place(i, :item_title, ok_button:'Salva', cancel_button:'Annulla modifiche',
                          ok_button_class:'btn btn-success',
                          class:'btn btn-default',
                          skip_blur:false,
                          html_attrs:{size:i.item_title.size}
                          )
      else
        bip=i.item_title
      end

      if i.item_id!=prec_item and !i.clavis_item.nil?
        if i.item_id.nil?
          lnk_item = ''
        else
          # lnk_item = link_to(i.collocazione, i.clavis_item.clavis_url, target: '_blank')
          lnk_item = link_to(i.collocazione, clavis_item_path(i.item_id), target: '_blank')
          inventario = i.clavis_item.inventario
        end
      else
        lnk_item = ''
        inventario=''
      end
      if i.consistency_note_id!=prec_cons
        lnk_consistenza = i.consistency_note_id.nil? ? '' : link_to('[Periodico]', clavis_consistency_note_path(i.consistency_note_id), target: '_blank')
      else
      end

      prec_mid=i.manifestation_id
      prec_item=i.item_id
      prec_cons=i.consistency_note_id

      delete_button=%Q{<button type="button" class="close" aria-label="Close" title="Rimuovi volume"><span aria-hidden="true">&times;</span></button>}

      res << content_tag(:tr,
                         content_tag(:td, link_to(delete_button.html_safe, i, remote:true, method: :delete,
                          confirm: "Confermi rimozione del volume #{i.collocazione}?")) +
                         content_tag(:td, lnk_item) +
                         content_tag(:td, lnk_opac.html_safe) +
                         content_tag(:td, bip) +
                         content_tag(:td, inventario) +
                         content_tag(:td, lnk_consistenza), id: "item_#{i.id}")
    end
    res=content_tag(:table, res.join.html_safe, :class=>'table')
  end
  def container_info(record)
    if record.container_items.size==0
      msg="Contenitore vuoto "
      msg += link_to('[elimina contenitore]', record, method: :delete, confirm: "Confermi cancellazione del contenitore #{record.label}?")
    else
      msg="Contiene #{@container.container_items.size} volumi"
    end
    content_tag(:div, msg.html_safe, id: "container_info_#{record.id}")
  end

  def container_items_list(records)
    res=[]
    cnt=0
    res << content_tag(:tr, content_tag(:td, 'Consistenza') +
                       content_tag(:td, '') +
                       content_tag(:td, 'Contenitore') +
                       content_tag(:td, 'Deposito') +
                       content_tag(:td, 'Prenotabile') +
                       content_tag(:td, 'Note'))
    records.each do |r|
      cnt+=1
      res << content_tag(:tr, content_tag(:td, r.consistenza) +
                         content_tag(:td, r.issue_description) +
                         content_tag(:td, r.contenitore) +
                         content_tag(:td, content_tag(:b, r.deposito)) +
                         content_tag(:td, (r.prenotabile? ? 'sì' : 'no') ) +
                         content_tag(:td, "#{r.note} item_id: #{r.item_id}"))
    end
    cnt==0? '' : content_tag(:table, res.join.html_safe, :class=>'table table-striped')
  end

end

