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
      res << content_tag(:tr, content_tag(:td, link_to(r.collocazione, clavis_item_path(r))) +
                         content_tag(:td, r.item_media_type) +
                         content_tag(:td, link_to(r.title, r.clavis_url(:show), :target=>'_blank')) +
                         content_tag(:td, r.inventario),
                         {:data_view=>r.view})
    end
    res << content_tag(:div, "Trovati #{records.total_entries} esemplari", class: 'panel-heading')
    res=content_tag(:table, res.join.html_safe, {:id=>table_id, class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clavis_items_shortlist_signed_in(records, table_id='items_list')
    return 'please sign in' if !user_signed_in?
    return '' if records.size==0
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.collocazione, r, remote: true,
                                                       onclick: %Q{$('#item_#{r.id}').html('<b>aspetta...</b>')}),
                                          id: "item_#{r.id}") +
                         content_tag(:td, r.item_media_type) +
                         content_tag(:td, link_to(r.title, r.clavis_url(:show), :target=>'_blank')) +
                         content_tag(:td, r.inventario),
                         {:data_view=>r.view})
    end
    res << content_tag(:div, "Trovati #{records.total_entries} esemplari - contenitore corrente: #{@clavis_item.current_container}", class: 'panel-heading')
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
