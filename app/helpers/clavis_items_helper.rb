module ClavisItemsHelper
  def clavis_item_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      case k
      when 'collocation'
        txt = link_to(record[k], "/clavis_items?clavis_item%5Bcollocation%5D=#{record[k]}")
      when 'manifestation_id'
        txt = record[k]==0 ? 'FUORI CATALOGO' : link_to(record[k], clavis_manifestation_path(record[k]))
      else
        txt = record[k]
      end
      res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, txt))
    end
    res=content_tag(:table, res.join.html_safe)
  end

  def clavis_items_shortlist(records, table_id='items_list')
    # return '' if records.size==0
    res=[]
    # Eventuale link a qualcosa:
    # content_tag(:td, link_to('[presta]', r.clavis_url(:loan), :target=>'_blank'))
    records.each do |r|
      if r.home_library_id==-1
        lnk=r.title
        media = 'TOPOGRAFICO'
      else
        lnk=link_to(r.title, r.clavis_url(:show), :target=>'_blank')
        media = r.item_media_type
        media << "</br>fuori catalogo" if r.manifestation_id==0
      end
      res << content_tag(:tr, content_tag(:td, link_to(r.collocazione.sub(/^BCT\./,''), clavis_item_path(r))) +
                         content_tag(:td, media.html_safe) +
                         content_tag(:td, lnk.html_safe) +
                         content_tag(:td, r.inventario),
                         {:data_view=>r.view})
    end
    # res << content_tag(:div, "Trovati #{records.total_entries} esemplari", class: 'panel-heading')
    res << content_tag(:div, "#{records.total_entries} esemplari (#{@sql_conditions})", class: 'panel-heading')
    res=content_tag(:table, res.join.html_safe, {:id=>table_id, class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clavis_items_ricollocazioni(records,dest_section=nil)
    return '' if records.size==0
    res=[]
    res << content_tag(:div, "#{records.total_entries} esemplari", class: 'panel-heading')
    # res << content_tag(:div, "#{records.total_entries} esemplari (#{@sql_conditions})", class: 'panel-heading')

    prec_descr=''
    records.each do |r|
      if @sort=='dewey'
        c1=r['dewey_collocation']
        c2 = r.full_collocation
        if r.descrittore!=prec_descr
          res << content_tag(:tr, content_tag(:td, content_tag(:b, r.descrittore), {colspan:5}))
          prec_descr=r.descrittore
        end
      else
        c1 = r.full_collocation
        c2=r['dewey_collocation']
      end
      c1+="<br/><b>#{r.usage_count}</b> prestit#{r.usage_count==1?'o':'i'}"
      c2+="<br/>#{r.serieinv}"
      c2+="<br/>In deposito esterno: <b>#{r.contenitore}</b>" if !r.contenitore.blank?

      in_opac=r.opac_visible==1 ? '' : '<b>non visibile in opac</b>'
      lnk=open_shelf_item_toggle(r.item_id, r.open_shelf_item_id.nil? ? true : false, @dest_section)

      item_info = "#{r.item_status}<br/><b>#{r.loan_status}</b>".html_safe
      if user_signed_in? and [9].include?(current_user.id)
        item_info = link_to(item_info, ClavisItem.clavis_url(r.item_id,:edit),:target=>'_blank')
      end

      res << content_tag(:tr,
                         content_tag(:td, item_info) +
                         content_tag(:td, c1.html_safe) +
                         content_tag(:td, c2.html_safe) +
                         content_tag(:td, "#{lnk}<br/>#{in_opac}".html_safe, id:"item_#{r.item_id}", style:"width:10em") +
                         content_tag(:td, link_to(r.title, ClavisManifestation.clavis_url(r.manifestation_id,:opac), :target=>'_blank'), style:"20em") +
                         content_tag(:td, "<b>#{r.edition_date}</b><br/>#{r.publisher}".html_safe))
    end
    res=content_tag(:tbody, res.join.html_safe)
    res=content_tag(:table, res, {class: 'table table-striped'})
  end


  def clavis_items_shortlist_signed_in(records, table_id='items_list')
    return 'please sign in' if !user_signed_in?
    return '' if records.size==0
    topografico = params[:clavis_item][:collocation].blank? ? false : true
    res=[]
    prec_catena=0
    records.each do |r|
      if r.home_library_id==-1
        lnk=r.title.gsub("\r",'; ')
        # url="http://sbct.comperio.it/index.php?page=Catalog.ItemInsertPage&collocation=#{r.collocation}&section=BCT&item_title=#{lnk}&ser=#{r.inventory_serie_id}&inv=#{r.inventory_number}"
        # lnk += "<br/>#{link_to('Inserisci in Clavis',url, :target=>'_blank')}"
        if !current_user.containers_enabled?
          mlnk = link_to('TOPOGRAFICO', edit_extra_card_path(r.custom_field3))
          mlnk << link_to('<br/>[elimina]'.html_safe, extra_card_path(r.custom_field3), remote:true,
                          method: :delete, data: { confirm: "Confermi cancellazione?" })
        else
          mlnk = 'TOPOGRAFICO'
        end
      else
        lnk=link_to(r.title, r.clavis_url(:show), :target=>'_blank')
        mlnk=r.manifestation_id==0 ? r.item_media_type : link_to(r.item_media_type,clavis_manifestation_path(r.manifestation_id, target_id: "item_#{r.id}"), :title=>"manifestation_id #{r.manifestation_id}", remote: true) + "<br/>#{r.manifestation_id}".html_safe
      end
      container_link = r.label.nil? ? '' : link_to(r.label, containers_path(:label=>r.label), target:'_blank') + "<br/>item_id:#{r.id}".html_safe
      colloc=r.collocazione.sub(/^BCT\./,'')
      if !current_user.containers_enabled?
        coll=link_to(colloc, clavis_item_path(r))
        catena=colloc.split('.').last.to_i
        if catena-prec_catena>1 and false
          [prec_catena..catena-1].each do |num|
            res << content_tag(:tr, content_tag(:td, num) +
                               content_tag(:td, prec_catena) +
                               content_tag(:td, catena) +
                               content_tag(:td, '') +
                               content_tag(:td, ''))
          end
          prec_catena=catena+1
        end
      else
        coll=link_to(colloc, r, remote: true, onclick: %Q{$('#item_#{r.id}').html('<b>aspetta...</b>')})
      end
      res << content_tag(:tr, content_tag(:td, coll.html_safe, id: "item_#{r.id}") +
                         content_tag(:td, mlnk) +
                         content_tag(:td, lnk.html_safe + "<br/>#{r.issue_description}".html_safe) +
                         content_tag(:td, r.inventario) +
                         content_tag(:td, container_link),
                         {:data_view=>r.view})
    end
    if current_user.containers_enabled?
      clink=link_to(@clavis_item.current_container, containers_path(:label=>@clavis_item.current_container), target:'_blank')
      res << content_tag(:div, "Trovati #{records.total_entries} esemplari - contenitore corrente: #{clink} (fare click sulla collocazione per inserire il volume corrispondente nel contenitore)".html_safe, class: 'panel-heading')
    end
    res=content_tag(:table, res.join.html_safe, {:id=>table_id, class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end


  def clavis_items_periodici_e_fatture(records)
    return '' if records.size==0
    hstatus = {
      'A' => 'Arrivato',
      'M' => 'Mancante',
      'N' => 'Arrivo previsto',
      'P' => 'Prossimo arrivo',
      'U' => 'Ultimo arrivo'
    }
    res=[]
    cnt=0
    records.each do |r|
      cnt+=1
      info_fattura=r['info_fattura']
      info=[]
      fatture=[]
      items_info={}
      info_fattura.split(',').each do |f|
        item_id,issue_status,invoice_id=f.split
        items_info[issue_status]=[] if items_info[issue_status].nil?
        items_info[issue_status] << item_id
        # info << "issue_status=#{issue_status} => #{link_to(item_id,ClavisItem.clavis_url(item_id))}"
        if invoice_id!='0'
          fatture << %Q{<div class="alert alert-success">#{link_to("Fattura #{invoice_id}", "http://sbct.comperio.it/index.php?page=Acquisition.InvoiceViewPage&id=#{invoice_id}", class: 'alert-link', target: '_blank')} su esemplare #{link_to(item_id,ClavisItem.clavis_url(item_id,:edit))} (#{hstatus[issue_status]})</div>}
        end
      end
      fatture << content_tag(:div, 'Non fatturato', class: 'alert alert-danger') if fatture.size==0
      fatture << link_to('fattura celdes (prova)', excel_cell_path(r['excel_cell_id'])) if !r['excel_cell_id'].nil? and r['issue_year']=='2014'
      items_info.each_pair do |k,v|
        lnk = v.size==1 ? link_to(hstatus[k],ClavisItem.clavis_url(v.first,:edit)) : hstatus[k]
        info << "#{lnk} (#{v.size})"
      end
      res << content_tag(:tr, content_tag(:td, "#{r['issue_year']}.#{cnt}") +
                         content_tag(:td, link_to(r['title'],ClavisManifestation.clavis_url(r['manifestation_id'])), :style=>'width: 50%') +
                         content_tag(:td, fatture.join('</br>').html_safe) +
                         content_tag(:td, info.join('</br>').html_safe))

      # invoice=fattura.nil? ? 'non fatturato': 
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

end
