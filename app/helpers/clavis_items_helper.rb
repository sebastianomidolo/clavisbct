# coding: utf-8
module ClavisItemsHelper
  def clavis_item_show(record)
    res=[]

    if record[:owner_library_id]==-3
      ci=ClavisItem.find(record[:custom_field1])
      record[:collocation] = "#{ci.custom_field1}, collocazione attuale #{ci.la_collocazione}"
    else

    end

    record.attributes.keys.each do |k|
      next if record[k].blank?
      case k
      when 'item_id'
        if record[:owner_library_id]==-3
          txt = link_to(record[:custom_field1], ClavisItem.clavis_url(record[:custom_field1],:edit))
        else
          if record[:owner_library_id]==-1
            txt = link_to(record[k], extra_card_path(record[:custom_field3]))
          else
            txt = link_to(record[k], ClavisItem.clavis_url(record[k]))
          end
        end
      when 'manifestation_id'
        txt = record[k]==0 ? 'FUORI CATALOGO' : link_to(record[k], clavis_manifestation_path(record[k]))
      else
        txt = record[k]
      end
      res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, txt))
    end
    res=content_tag(:table, res.join.html_safe)
  end

  def clavis_items_row(record)
    edit_in_place=false
    coll=record.collocazione
    mlnk = link_to('TOPOGRAFICO', edit_extra_card_path(record.custom_field3))

    if record.owner_library_id==-1
      lnk=record.title.gsub("\r",'; ')
      if can? :manage, ExtraCard
        edit_in_place=true
        extra_card=ExtraCard.find(record.custom_field3)
        mlnk = link_to('TOPOGRAFICO', edit_extra_card_path(record.custom_field3))
        mlnk << link_to('<br/>[elimina]'.html_safe, extra_card_path(record.custom_field3), remote:true,
                        method: :delete, data: { confirm: "Confermi cancellazione? (#{current_user.email})" })
        mlnk << link_to('[duplica]'.html_safe, record_duplicate_extra_card_path(record.custom_field3), remote:true,
                        method: :post)
      else
        mlnk = 'TOPOGRAFICO'
      end
    else
      if record.owner_library_id==-3
        lnk=link_to(record.title, ClavisItem.clavis_url(record.custom_field1,:show), :target=>'_blank')
      else
        lnk=link_to(record.title, record.clavis_url(:show), :target=>'_blank')
      end
    end

    colloc=record.collocazione.sub(/^BCT\./,'')
    if can? :manage, Container and !@clavis_item.current_container.nil?
      coll=link_to(colloc, record, remote: true, onclick: %Q{$('#item_#{record.id}').html('<b>aspetta...</b>')})
    else
      coll=link_to(colloc, clavis_item_path(record))
    end
    piano = record.piano_centrale
    classe = ''

    if edit_in_place
      stringa_titolo=lnk.html_safe
      stringa_titolo=best_in_place(extra_card, :titolo, ok_button:'Salva', cancel_button:'Annulla modifiche',
                                   ok_button_class:'btn btn-success',
                                   class:'btn btn-default',
                                   skip_blur:false,
                                   html_attrs:{size:extra_card.titolo.size,style:'display: block'})
      coll=best_in_place(extra_card, :collocazione, ok_button:'Salva', cancel_button:'Annulla modifiche',
                         ok_button_class:'btn btn-success',
                         class:'btn btn-default',
                         skip_blur:false,
                         html_attrs:{size:extra_card.collocazione.size,style:'display: block'})
      stringa_titolo+="<br/>#{extra_card.note_interne}".html_safe if !extra_card.note_interne.blank?
    else
      stringa_titolo=lnk.html_safe + "<br/>#{r.issue_description}".html_safe
    end
    coll << "</br>#{piano}".html_safe if !piano.nil?

    container_link=''
    content_tag(:tr, content_tag(:td, coll.html_safe, id: "item_#{record.id}") +
                     content_tag(:td, mlnk) +
                     content_tag(:td, stringa_titolo) +
                     content_tag(:td, record.inventario) +
                     content_tag(:td, container_link),
                {:data_view=>record.view,:class=>classe})

    # mlnk = "prova"
    # content_tag(:tr, content_tag(:td, record.collocazione.html_safe) +
    #                  content_tag(:td, mlnk) +
    #                  content_tag(:td, record.title) +
    #                  content_tag(:td, record.id))
  end

  def clavis_items_rawlist(records)
    return '' if records.size==0
    res=[]
    records.each do |r|
      lnk=link_to(r.title, r.clavis_url(:show), :target=>'_blank')
      res << content_tag(:tr, content_tag(:td, lnk))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clavis_items_shortlist(records, table_id='items_list')
    return '' if records.size==0
    res=[]

    prec_catena=0
    records.each do |r|
      edit_in_place=false
      if r.owner_library_id==-1
        lnk=r.title.gsub("\r",'; ')
        if can? :manage, ExtraCard
          edit_in_place=true
          extra_card=ExtraCard.find(r.custom_field3)
          mlnk = link_to('TOPOGRAFICO', edit_extra_card_path(r.custom_field3))
          mlnk << link_to('<br/>[elimina]'.html_safe, extra_card_path(r.custom_field3), remote:true,
                          method: :delete, data: { confirm: "Confermi cancellazione? (#{current_user.email})" })
          mlnk << link_to('[duplica]'.html_safe, record_duplicate_extra_card_path(r.custom_field3), remote:true,
                          method: :post)
        else
          mlnk = 'TOPOGRAFICO'
        end
      else
        if r.owner_library_id==-3
          lnk=link_to(r.title, ClavisItem.clavis_url(r.custom_field1,:show), :target=>'_blank')
        else
          lnk=link_to(r.title, r.clavis_url(:show), :target=>'_blank')
        end
        media = r.item_media_type.nil? ? 'Media type ignoto' : r.item_media_type
        media << "</br>fuori catalogo" if r.manifestation_id==0
        media << "</br><em>#{r.item_status}</em>"
        media << "</br><b>#{r.loan_status}</b>"
        lnk << "</br><b>non visibile in opac</b>".html_safe if r.opac_visible!=1
        lnk << "</br><em>rfid: #{r.rfid_code}</em>".html_safe if !r.rfid_code.blank?
        if !r.date_created.nil?
          lnk << "</br>Creato il #{r.date_created.to_date} (#{r.created_by}) - Ultima modifica: #{r.date_updated.to_date} (#{r.modified_by})".html_safe if !r.date_updated.nil?
        end
        lnk << "</br>#{link_to('[vedi notizia]', ClavisManifestation.clavis_url(r.manifestation_id,:show),:target=>'_blank')}".html_safe if r.manifestation_id!=0
        
        mlnk=r.manifestation_id==0 ? media.html_safe : link_to(media.html_safe,clavis_manifestation_path(r.manifestation_id, target_id: "item_#{r.id}"), :title=>"manifestation_id #{r.manifestation_id}", remote: true)
      end
      container_link = r.label.nil? ? '' : link_to(r.label, containers_path(:label=>r.label), target:'_blank') + "<br/>item_id:#{r.id}".html_safe

      colloc=r.collocazione.sub(/^BCT\./,'')
      if can? :manage, Container and !@clavis_item.current_container.nil?
        coll=link_to(colloc, r, remote: true, onclick: %Q{$('#item_#{r.id}').html('<b>aspetta...</b>')})
      else
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
      end
      classe = r.owner_library_id==-3 ? 'success' : ''

      if edit_in_place
        stringa_titolo=lnk.html_safe
        stringa_titolo=best_in_place(extra_card, :titolo, ok_button:'Salva', cancel_button:'Annulla modifiche',
                                     ok_button_class:'btn btn-success',
                                     class:'btn btn-default',
                                     skip_blur:false,
                                     html_attrs:{size:extra_card.titolo.size,style:'display: block'})
        coll=best_in_place(extra_card, :collocazione, ok_button:'Salva', cancel_button:'Annulla modifiche',
                           ok_button_class:'btn btn-success',
                           class:'btn btn-default',
                           skip_blur:false,
                           html_attrs:{size:extra_card.collocazione.size,style:'display: block'})
        stringa_titolo+="<br/>#{extra_card.note_interne}".html_safe if !extra_card.note_interne.blank?
      else
        if r.item_media=='S'
          arrivato_il = r.issue_arrival_date.blank? ? '' : " - Arrivato il #{r.issue_arrival_date}"
          lnk_cons = link_to(' [consistenza]',list_by_manifestation_id_clavis_consistency_notes_path(id:r.manifestation_id), :target=>'_blank')
          stringa_titolo="[#{r.manifestation_id}] #{lnk}".html_safe + "#{lnk_cons}<br/><b>#{r.issue_description}#{arrivato_il}</b>".html_safe
        else
          stringa_titolo=lnk.html_safe
        end
      end

      coll << "</br>RICOLLOCATO".html_safe if r.owner_library_id==-3
      coll << "</br>#{r.piano}".html_safe if !r.piano.nil?
      coll << "</br><em>#{r.requests_count} #{r.requests_count=='1' ? 'prenotazione' : 'prenotazioni' }</em>".html_safe if r.respond_to?('requests_count')

      res << content_tag(:tr, content_tag(:td, coll.html_safe, id: "item_#{r.id}") +
                              content_tag(:td, mlnk) +
                              content_tag(:td, stringa_titolo) +
                              content_tag(:td, r.inventario) +
                              content_tag(:td, container_link),
                         {:data_view=>r.view,:class=>classe})
    end
    if can? :manage, Container and !@clavis_item.current_container.nil?
      clink=link_to(@clavis_item.current_container, containers_path(:label=>@clavis_item.current_container), target:'_blank')
      res << content_tag(:div, "Trovati #{records.total_entries} esemplari".html_safe, class: 'panel-heading')
    else
      res << content_tag(:div, "Trovati #{records.total_entries} esemplari".html_safe, class: 'panel-heading')
    end
    res=content_tag(:table, res.join("\n").html_safe, {:id=>table_id, class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clavis_items_ricollocazioni(records,dest_section=nil)
    return '' if records.size==0
    res=[]
    res << content_tag(:div, "#{records.total_entries} esemplari", class: 'panel-heading')
    # res << content_tag(:div, "#{records.total_entries} esemplari (#{@sql_conditions})", class: 'panel-heading')

    if records.total_entries>100 and !@class_id.blank?
      res << content_tag(:span, link_to("Tutti (non funziona per ora) - class_id #{@class_id}",titles_open_shelf_items_path(format:'html',class_id:@class_id,dest_section:dest_section)))
    end
    sections=OpenShelfItem.sections.collect {|x| x.last }
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
      c2+="<br/><b>#{r.vedetta[0..3]}</b>" if r.os_section=='CCNC'
      c2+="<br/>In deposito esterno: <b>#{r.contenitore}</b>" if !r.contenitore.blank?

      in_opac=r.opac_visible==1 ? '' : '<b>non visibile in opac</b>'
      lnk=open_shelf_item_toggle(r.item_id, r.open_shelf_item_id.nil? ? true : false, sections, @dest_section)

      item_info = "#{r.item_status}<br/><b>#{r.loan_status}</b>".html_safe
      # if user_signed_in? and [4,9].include?(current_user.id)
      if can? :ricollocazioni, ClavisItem
        item_info = link_to(item_info, ClavisItem.clavis_url(r.item_id,:show),:target=>'_blank')
      end

      res << content_tag(:tr,
                         content_tag(:td, item_info) +
                         content_tag(:td, c1.html_safe) +
                         content_tag(:td, c2.html_safe) +
                         content_tag(:td, "#{lnk}<br/>#{in_opac}".html_safe, id:"item_#{r.item_id}", style:"width:22em") +
                         content_tag(:td, link_to(r.title, ClavisManifestation.clavis_url(r.manifestation_id,:show), :target=>'_blank'), style:"20em") +
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
        if can? :manage, ExtraCard
          mlnk = link_to('TOPOGRAFICO', edit_extra_card_path(r.custom_field3))
          mlnk << link_to('<br/>[elimina]'.html_safe, extra_card_path(r.custom_field3), remote:true,
                          method: :delete, data: { confirm: "Confermi cancellazione?" })
        else
          mlnk = 'TOPOGRAFICO'
        end
      else
        lnk=link_to(r.title, r.clavis_url(:show), :target=>'_blank')
        media = r.item_media_type
        media << "</br>fuori catalogo" if r.manifestation_id==0
        media << "</br><em>#{r.item_status}</em>"
        media << "</br><b>#{r.loan_status}</b>"
        mlnk=r.manifestation_id==0 ? media.html_safe : link_to(media.html_safe,clavis_manifestation_path(r.manifestation_id, target_id: "item_#{r.id}"), :title=>"manifestation_id #{r.manifestation_id}", remote: true)
      end
      container_link = r.label.nil? ? '' : link_to(r.label, containers_path(:label=>r.label), target:'_blank') + "<br/>item_id:#{r.id}".html_safe
      colloc=r.collocazione.sub(/^BCT\./,'')
      if can? :manage, Container
        coll=link_to(colloc, r, remote: true, onclick: %Q{$('#item_#{r.id}').html('<b>aspetta...</b>')})
      else
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
      end
      res << content_tag(:tr, content_tag(:td, coll.html_safe, id: "item_#{r.id}") +
                         content_tag(:td, mlnk) +
                         content_tag(:td, lnk.html_safe + "<br/>#{r.issue_description}".html_safe) +
                         content_tag(:td, r.inventario) +
                         content_tag(:td, container_link),
                         {:data_view=>r.view})
    end

    if can? :manage, Container
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

  def clavis_item_info(record)
    # return clavis_item_formatta_info('test')
    info=record.item_info
    # return "info: #{record.inspect}"
    return '' if info.nil?
    res=[]
    res << "Scaffale aperto - sezione #{info['os_section']}" if !info['os_section'].blank?
    res << "In deposito esterno: contenitore #{info['label']} - si trova presso #{info['nomebib']}" if !info['label'].blank?
    res << content_tag(:b, " Collocazione in Civica Centrale: #{info['piano']}") if !info['piano'].blank? and record.home_library_id==2
    res << " <em>(sulla notizia è presente almeno una prenotazione)</em>" if record.controlla_prenotazioni
    if !info['daily_counter'].blank?
      res << %Q{<h2>Richiesta a magazzino numero <b>#{info['daily_counter']}</b>
         - utente #{link_to(info['lastname'], ClavisPatron.clavis_url(info['patron_id'],:newloan), target:'_blank')}</h2>}
      res << %Q{Ora della conferma di richiesta: <em>#{closed_stack_item_requests_ora(info['confirm_time'])}</em>,
                #{info['printed']=='t' ? "" : "non "}stampata #{closed_stack_item_requests_ora(info['print_time'])} [#{info['csir_id']}]}
    end
    clavis_item_formatta_info(res.join.html_safe)
  end

  def clavis_item_formatta_info(string)
    return '' if string.blank?
    # content_tag(:span, content_tag(:b, string.html_safe),style:'margin-left: 180px')
    content_tag(:div, string, style:'margin-left: 180px')
  end

  def clavis_items_simple_list(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'data') +
                            content_tag(:td, 'rist') +
                            content_tag(:td, 'titolo') +
                            content_tag(:td, 'item') +
                            content_tag(:td, 'volume_text'))
    records.each do |r|
      lnk_cm=link_to(r.title, ClavisManifestation.clavis_url(r.manifestation_id, :show), :target=>'_blank')
      lnk_ci=link_to("item #{r.item_id}", r.clavis_url(:edit), :target=>'_blank')

      res << content_tag(:tr, content_tag(:td, r.edition_date) +
                              content_tag(:td, r.reprint) +
                              content_tag(:td, lnk_cm) +
                              content_tag(:td, lnk_ci) +
                              content_tag(:td, r.volume_text))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clavis_items_valori_inventariali(records)
    res=[]
    header=content_tag(:tr, content_tag(:td, 'Prezzo/val.inv.') +
                            content_tag(:td, 'Sconto') +
                            content_tag(:td, 'Importo') +
                            content_tag(:td, 'Data inventario') +
                            content_tag(:td, 'Creato da') +
                          content_tag(:td, 'Titolo'))
    res << header
    records.each do |r|
      lnk_ci=link_to("#{r.title[0..20]}", r.clavis_url(:edit), :target=>'_blank')
      res << content_tag(:tr,
                         content_tag(:td, r.inventory_value) +
                         content_tag(:td, r.discount_value) +
                         content_tag(:td, r.currency_value) +
                         content_tag(:td, r.inventory_date) +
                         content_tag(:td, r.created_by) +
                         content_tag(:td, lnk_ci))
    end
    res << header
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end


  def clavis_items_missing_numbers(collocazione)
    return '' if collocazione.blank?
    scaffale,palchetto=collocazione.split('.')
    return '' if palchetto.nil? or scaffale.to_i == 0
    nc=ClavisItem.missing_numbers(scaffale.to_i,palchetto.upcase)
    return '' if nc.size==0
    nclink=[]
    nc.each do |n|
      nclink << link_to(n, new_extra_card_path(collocazione:"#{collocazione}.#{n}"),target:'_blank') if can? :manage, ExtraCard
    end
    "Numeri di catena non presenti in <b>#{scaffale}.#{palchetto.upcase}</b>: #{nclink.join(', ')}".html_safe
  end

  def clavis_items_senza_copertina(records)
    res=[]
    records.each do |r|
      ean = ''
      if r['EAN'].blank?
        ean = r['ISBNISSN'].blank? if !r['ISBNISSN'].blank?
      else
        ean = r['EAN']
      end
      img_link = ean.blank? ? '' : image_tag("https://covers.comperio.it/calderone/viewmongofile.php?ean=#{ean}")
      res << content_tag(:tr, content_tag(:td, img_link) +
                              content_tag(:td, ean.blank? ? '-' : ean) +
                              content_tag(:td, link_to(r['title'], ClavisManifestation.clavis_url(r['manifestation_id'],:edit))) +
                              content_tag(:td, link_to('[opac]', ClavisManifestation.clavis_url(r['manifestation_id'],:opac))) +
                              content_tag(:td, r[:title]))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end
end
