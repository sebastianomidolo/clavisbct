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
    delete_button=%Q{<button type="button" class="close" aria-label="Close" title="Rimuovi volume"><span aria-hidden="true">&times;</span></button>}

    record.elements.each do |r|
      inventario=nil
      title = r['titolo']
      lnk_opac=title

      item_title=r['container_item_title']
      if item_title.nil?
        bip=title
        del = content_tag(:td, link_to(delete_button.html_safe,
                                       remove_from_container_extra_card_path(r['extra_card_id']),
                                       remote:true, method: :post,
                                       confirm: "X Confermi rimozione del volume #{r['collocazione']}?"))
        del_id = "extra_card_id_#{r['extra_card_id']}"
      else
        if r['manifestation_id']!=0
          lnk_opac="#{link_to(title, ClavisManifestation.clavis_url(r['manifestation_id'],:opac), target: '_blank')} #{link_to('<b>[edit]</b>'.html_safe, ClavisItem.clavis_url(r['item_id'],:show), target: '_blank')}"
        end
        if can? :manage, Container and !r['container_item_id'].nil?
          i=ContainerItem.find(r['container_item_id'])
          del = content_tag(:td, link_to(delete_button.html_safe, i, remote:true, method: :delete,
                                         confirm: "Y Confermi rimozione del volume #{r['collocazione']}?"))
          del_id = "item_#{i.id}"
          bip=best_in_place(i, :item_title, ok_button:'Salva', cancel_button:'Annulla modifiche',
                            ok_button_class:'btn btn-success',
                            class:'btn btn-default',
                            skip_blur:false,
                            html_attrs:{size:i.item_title.size}
                           )
        else
          bip=title
          del = ''
        end
      end

      lnk_item = r['collocazione']
      inventario=''

      res << content_tag(:tr, del +
                         content_tag(:td, lnk_item) +
                         content_tag(:td, lnk_opac.html_safe) +
                         content_tag(:td, bip) +
                         content_tag(:td, inventario), id: del_id)
    end
    res=content_tag(:table, res.join.html_safe, :class=>'table')
  end

  def container_info(record)
    if record.elements.size==0
      msg="Contenitore vuoto "
      msg += link_to('[elimina contenitore]', record, method: :delete, confirm: "Confermi cancellazione del contenitore #{record.label}?")
    else
      msg="Contiene #{@container.elements.size} volumi"
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

