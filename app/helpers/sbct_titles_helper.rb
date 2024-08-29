# coding: utf-8
module SbctTitlesHelper

  def sbct_titles_con_prenotazioni(records)
    res = []
    heading = content_tag(:tr, content_tag(:td, 'Copertina', class:'col-md-1') +
                            content_tag(:td, 'Titolo', class:'col-md-4') +
                            content_tag(:td, 'EAN/ISBN', class:'col-md-1') +
                            content_tag(:td, 'Prenotazioni pendenti', class:'col-md-1') +
                            content_tag(:td, 'Esemplari disponibili', class:'col-md-1') +
                               content_tag(:td, 'Percentuale di prenotazioni che possono essere soddisfatte', class:'col-md-4'), class:'success')
    res << heading
    records.each do |r|
      ean = r.ISBNISSN.blank? ? r.EAN : r.ISBNISSN
      # img_link = image_tag("https://covers.comperio.it/calderone/viewmongofile.php?ean=#{ean}")
      img_link = image_tag("https://covers.biblioteche.cloud/covers/#{ean}")
      lnkean = r.acquisti_id_titolo.nil? ? "#{ean}<br/>(non individuato sul db acquisti)".html_safe : link_to(ean, sbct_title_path(r.acquisti_id_titolo), {title:'Vedi in PAC', target:'_blank'})
      res << content_tag(:tr, content_tag(:td, link_to(img_link,r.clavis_url, target:'_blank')) +
                              content_tag(:td, link_to(r.title, r.clavis_url, target:'_blank', title:'Vedi in Clavis')) +
                              content_tag(:td, "#{lnkean}<br/><b>#{r.reparto}</b><br/>#{r.sottoreparto}".html_safe) +
                              content_tag(:td, r.reqnum) +
                              content_tag(:td, r.available_items) +
                              content_tag(:td, r.percentuale_di_soddisfazione + '%'))
    end
    res << heading
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def sbct_short_titles_list(records, table_title='')
    return '' if records.size==0
    res = []
    res << content_tag(:tr, content_tag(:td, "EAN") +
                            content_tag(:td, "Titolo") +
                            content_tag(:td, "Autore"), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.ean, sbct_titles_path("sbct_title[ean]":r.ean,nosearchform:true), target:'_sbct_title', class:'btn btn-warning')) +
                              content_tag(:td, r.titolo) +
                              content_tag(:td, r.autore))
    end
    table_title + content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_titles_lastins_list(records,sbct_list)
    return '' if records.size==0
    res = []

    links = []
    links << link_to("in lista", sbct_list_path(sbct_list, order:'gl'), title:'Ordina per numero di giorni da inserimento in lista')
    links << link_to("data pubblicazione", sbct_list_path(sbct_list, order:'gp'), title:'Ordina per numero di giorni dalla data di pubblicazione')

    res << content_tag(:tr, content_tag(:td, "Lista", class:'col-md-2') +
                            content_tag(:td, "Inserito&nbsp;da".html_safe, class:'col-md-1') +
                            content_tag(:td, "#{link_to('Titolo', sbct_list_path(sbct_list))} (#{links.join(' ')})".html_safe, class:'col-md-8') +
                            content_tag(:td, "Note", class:'col-md-1'), class:'success')
    records.each do |r|
      ulnk = r.username.blank? ? '-' : link_to(r.username, lastins_sbct_lists_path(username:r.username))
      msg = ''
      if r.days_before_autorm.to_i > 0
        ngg = r.days_before_autorm.to_i - r.gg_in_lista.to_i
        if ngg < 0
          msg = " - verrà rimosso al prossimo allineamento (domani)"
        else
          msg = " - verrà rimosso fra #{ngg} giorni"
        end
      end
      mymsg=r.gg_in_lista=='0' ? 'oggi' : "#{r.gg_in_lista} giorni fa#{msg}"
      specif = "#{link_to(r.titolo,r)}<br/><em>Inserito in lista: #{r.date_created.to_date} (#{mymsg})</em>"
      if !r.datapubblicazione.blank?
        msg = ''
        if r.pubbl_age_limit.to_i > 0
          ngg = r.pubbl_age_limit.to_i - r.gg_da_pubblicazione.to_i
          if ngg < 0
            msg = " - verrà rimosso al prossimo allineamento (domani)"
          else
            msg = " - verrà rimosso fra #{ngg} giorni"
          end
        end
        if r.gg_da_pubblicazione.to_i < 0
          msg=''
          # specif << "<br/>Data pubblicazione FUTURA: #{r.datapubblicazione} (fra #{r.gg_da_pubblicazione.to_i.abs} giorni#{msg})"
          specif << "<br/>Data pubblicazione FUTURA: #{r.datapubblicazione}"
        else
          mymsg=r.gg_da_pubblicazione=='0' ? 'oggi' : "#{r.gg_da_pubblicazione} giorni fa#{msg}"
          specif << "<br/>Data pubblicazione: #{r.datapubblicazione} (#{mymsg})"
        end
      end
      res << content_tag(:tr, content_tag(:td, link_to(r.order_sequence, sbct_list_path(r.root_id))) +
                              content_tag(:td, ulnk) +
                              content_tag(:td, specif.html_safe) +
                              content_tag(:td, r.note))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end
  
  def sbct_titles_list(records, managed_libraries=[])
    # checkbox_on = false
    checkbox_on = @sbct_item.nil? ? false : true
    res=[]
    covers = params[:nocovers].blank? ? content_tag(:td, 'copertina', class:'col-md-1') : ''
    check_column = checkbox_on==true ? content_tag(:td, '<b>x</b>'.html_safe, id:'check_column_ctrl', class:'col-md-1 btn', onclick:'toggle_titles(this);') : ''

    res << content_tag(:tr, check_column.html_safe + covers.html_safe +
                            content_tag(:td, 'autore', class:'col-md-2') +
                            content_tag(:td, 'titolo/collana', class:'col-md-3') +
                            content_tag(:td, 'editore', class:'col-md-2') +
                            content_tag(:td, 'siglebib', class:'col-md-3') +
                            content_tag(:td, 'isbn', class:'col-md-1'), class:'success')

    if managed_libraries.size > 6
      sel_span_1 = 1
      sel_span_2 = 7
    else
      sel_span_1 = covers.blank? ? 4 : 5
      sel_span_2 = covers.blank? ? 3 : 4
    end

    libraries_with_code={}
    ClavisLibrary.con_siglabct.collect {|r| libraries_with_code[r.siglabct]=r}

    id_lista = params[:id_lista]
    cnt = 0
    records.each do |r|
      cnt += 1
      if r.respond_to?('proposal_ids')
        pproposal_link = []
        r.proposal_ids.split(',').each do |tv|
          # pproposal_link << link_to('Vedi proposta',clavis_purchase_proposal_path(tv), target:'_clavis_purchase_proposal', class:'btn btn-warning')
          pproposal_link << content_tag(:span, link_to('Proposta lettore',clavis_purchase_proposal_path(tv), target:'_clavis_purchase_proposal'), class:'badge')
        end
        pproposal_link = pproposal_link.join(', ').html_safe
      else
        pproposal_link = ''
      end
      glink = r.isbn.blank? ? 'manca isbn' : link_to(r.isbn, "https://www.google.com/search?q=#{r.isbn}", target:'_blank', title:'Cerca su Google')
      extlnk = []
      if !r.isbn.blank?
        extlnk << r.isbn
        # extlnk << link_to('Leggere', "http://h3ol.leggere.it/?q=#{r.isbn}&p=ricercalibera".html_safe, target:'_blank', title:'Vedi su Leggere')
        # extlnk << link_to('IBS', "https://www.ibs.it/bct/e/#{r.isbn}".html_safe, target:'_blank', title:'Vedi su IBS')
        # extlnk << link_to('Google', "https://www.google.com/search?q=#{r.isbn}".html_safe, target:'_blank', title:'Vedi su Google')
        extlnk << sbct_titles_links_via_ean(r.isbn,r.manifestation_id)
        extlnk << pproposal_link if !pproposal_link.blank?
        # extlnk << " #{cnt}"
        # img_link = image_tag("https://covers.comperio.it/calderone/viewmongofile.php?ean=#{r.isbn}")
        img_link = image_tag("https://covers.biblioteche.cloud/covers/#{r.isbn}/C/0/P", {width:"180"})
        # img_link = image_tag("https://covers.biblioteche.cloud/covers/#{r.isbn}/C/0/P", {height:"200"})
        # img_link = image_tag("https://covers.biblioteche.cloud/covers/#{r.isbn}/C/0/P")
      else
        img_link = ''
      end
      lacollana = r.collana.blank? ? '' : "<br/><em>Collana: #{link_to(r.collana, sbct_titles_path("sbct_title[titolo]":"collana:#{r.collana}",id_lista:id_lista))}</em>".html_safe
      datapubbl = r.datapubblicazione.blank? ? '' : "<br/><b>Data di pubblicazione: #{r.datapubblicazione}</em>".html_safe
      anno = r.anno.blank? ? '' : "<br/><b>Anno: #{r.anno}</em>".html_safe
      reparto = r.reparto.blank? ? '' : "<br/><b>Reparto: #{r.reparto}</em>".html_safe
      data_inserimento = r.date_created.blank? ? '' : "<br/><b>DataIns: #{r.date_created.to_date}</b>".html_safe
      prezzo = r.prezzo.blank? ? "<br/><i>[prezzo mancante]</i>".html_safe : "<br/><b>Prezzo: #{number_to_currency(r.prezzo)}</b>".html_safe
      target_lettura = r.target_lettura.blank? ? '' : "<br/><b>Target lettura: #{r.target_lettura}</b>".html_safe

      in_liste_da = r.data_ins_in_lista.blank? ? '' : "<br/><b>InListeDa: #{r.data_ins_in_lista}</b>".html_safe
      note = r.note.blank? ? '' : "<br/><b>Note: #{r.note}</b>".html_safe
      
      ref_tit = link_to(r.titolo,sbct_title_path(r.id_titolo, :page=>params[:page], budget_id:params[:budget_id], id_lista:id_lista, selection_mode:params[:selection_mode]), target:'_blank')
      # if params[:nocovers].blank?

      ref_img = content_tag(:td, link_to(img_link,sbct_title_path(r.id_titolo, :page=>params[:page], budget_id:params[:budget_id], id_lista:id_lista, selection_mode:params[:selection_mode]), target:'_blank'))
      row_class = ''
      if check_column.blank?
        checkbox = ''
      else
        if @sbct_item.js_code == :switch_title
          if user_session[:tinybox].include?(r.id_titolo)
            checked=true
            row_class = 'warning'
          else
            checked=false
          end
          checkbox = content_tag(:td, check_box_tag("title_ids[]", r.id_titolo, checked, id:"title_check_#{r.id_titolo}", onclick:"add_or_remove_title_from_tinybox(this);"))
        else
          checkbox = content_tag(:td, check_box_tag("title_ids[]", r.id_titolo, true))
        end
      end

      begin
        lesigle = content_tag(:span, sbct_titles_format_infocopie(r.infocopie))
      rescue
        lesigle = "errore? #{r.infocopie}"
        # lesigle = "".html_safe
      end
      # lesigle = content_tag(:b, ClavisLibrary.library_ids_to_siglebct(r.library_ids).sort.join(', '), id:"toc_#{r.id_titolo}")
      numcopie = r.infocopie.split(',').size
      lesigle += "<br/>Totale: #{numcopie}".html_safe if numcopie.to_i > 1

      lesigle += "<br/>In Clavis: #{r.num_copie_in_clavis}".html_safe if r.respond_to?('num_copie_in_clavis')

      lnk_editore = r.editore.blank? ? '[editore mancante]' : link_to(r.editore, sbct_titles_path("sbct_title[titolo]":"editore:#{r.editore}",id_lista:id_lista))
      
      res << content_tag(:tr, content_tag(:td, '', colspan:sel_span_1) +
                              content_tag(:td, sbct_titles_user_checkbox(managed_libraries,@sbct_list,r.id,r.library_codes,libraries_with_code), colspan:sel_span_2),class:'active') if params[:selection_mode]=='S'
      res << content_tag(:tr, "#{checkbox}#{ref_img}".html_safe +
                              content_tag(:td, (r.autore.blank? ? '' : link_to(r.autore, sbct_titles_path("sbct_title[titolo]":"autore:#{r.autore}",id_lista:id_lista)))) +
                              content_tag(:td, ref_tit + prezzo + lacollana + datapubbl + anno + reparto + target_lettura + data_inserimento + in_liste_da + note) +
                              content_tag(:td, lnk_editore) +
                              content_tag(:td, lesigle) +
                              content_tag(:td, extlnk.join(' ').html_safe), id:"title_#{r.id}", class:row_class)
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed', id:'main_table_id')
end

def sbct_titles_format_infocopie(infocopie)
  return "-" if infocopie.size==1
  res = []
    style =
      {
        :A=>['Arrivato','span class="label label-success"'],
        :N=>['Non disponibile','span class="label label-warning"'],
        :O=>['Ordinato','span class="label label-primary"'],
        :S=>['Selezionato','span class="label label-default"'],
        :I=>['Stato indefinito','span'],
      }

    # :I=>['Indefinito','span style="background-color:#F7FFDD;color:black"'],
    # Esempio infocopie: "A-2-O,B-1-S,BEL-1-N"
    infocopie.split(',').uniq.each do |r|
      siglabib,numcopie,status = r.split('-')
      numcopie = numcopie.to_i
      title,tag=style[status.to_sym]
      if numcopie>1
        title = "#{title} (#{numcopie} copie per #{siglabib})"
      else
        numcopie=''
      end
      # res << "#{siglabib}|#{numcopie} status #{status} - title=#{title}"
      res << "<#{tag} title='#{title}'>#{siglabib}#{numcopie}</#{tag}>".html_safe
    end
    res.join(" \n").html_safe
  end

  def sbct_titles_user_checkbox(managed_libraries,sbct_list,id_titolo,library_codes,libraries_with_code)
    library_codes=library_codes.split(',')
    res = []
    managed_libraries.each do |e|
      res << %Q{#{e}#{check_box_tag :choose, true, library_codes.include?(e), onclick:"toggle_library_selection(this,'#{libraries_with_code[e].library_id}',#{id_titolo},#{sbct_list.id})"}}
    end
    res.join("\n").html_safe
  end

  def sbct_titles_links_via_ean(ean,manifestation_id=nil)
    res = []
    if !ean.blank?
      res << link_to('Leggere', "https://h3ol.leggere.it/?q=#{ean}&p=ricercalibera".html_safe, target:'leggere', title:'Vedi su Leggere')
      res << link_to('IBS', "https://www.ibs.it/bct/e/#{ean}".html_safe, target:'ibs', title:'Vedi su IBS')
      res << link_to('Google', "https://www.google.com/search?q=#{ean}".html_safe, target:'google', title:'Vedi su Google')
    end
    if !manifestation_id.nil?
      res << content_tag(:span, link_to('Clavis', ClavisManifestation.clavis_url(manifestation_id), target:'_clavis_manifestation'), class:'label label-info')
      res << content_tag(:span, link_to('Opac', ClavisManifestation.clavis_url(manifestation_id,:opac), target:'_clavis_opac'), class:'label label-info')
    end
    res
  end

  def sbct_titles_order_details(record)
    od=record.order_details
    return '' if od.size==0
    res=[]
    res << content_tag(:tr, content_tag(:td, 'ordine', class:'col-md-1') +
                            content_tag(:td, 'inviomerce', class:'col-md-1') +
                            content_tag(:td, 'bolla', class:'col-md-1') +
                            content_tag(:td, 'prezzo', class:'col-md-1') +
                            content_tag(:td, 'fattura', class:'col-md-1') +
                            content_tag(:td, 'evaso', class:'col-md-1') +
                            content_tag(:td, 'stato', class:'col-md-1') +
                            content_tag(:td, 'note', class:'col-md-2'), class:'success')
    od.each do |r|
      ordine = r.dataordine.nil? ? '' : r.dataordine.to_date
      inviomerce = r.datainviomerce.nil? ? '' : r.datainviomerce.to_date
      
      fattura = r.datafattura.nil? ? '' : "#{r.numerofattura}<br/>#{r.datafattura.to_date}".html_safe
      rif_ord = r.riferimentoordine.blank? ? '' : "<br/><small>Rif #{r.riferimentoordine} - #{r.progressivoordine}</small>".html_safe
      lnkbolla = r.numerobollaconsegna.nil? ? '' : link_to(r.numerobollaconsegna, delivery_notes_sbct_titles_path(dnoteid:"#{r.datainviomerce}|#{r.numerobollaconsegna}"), class:'btn btn-warning')
      if current_user.email=='sebaxx'
        lnkstato = r.stato == 'Evaso' ? "segna come arrivato" : r.stato
      else
        lnkstato = r.stato
      end
      res << content_tag(:tr, content_tag(:td, "#{ordine}#{}<br/><small>#{r.cliente}</small>".html_safe) +
                              content_tag(:td, "#{inviomerce}#{rif_ord}".html_safe) +
                              content_tag(:td, lnkbolla) +
                              content_tag(:td, "#{number_to_currency(r.prezzo)}<br/>#{number_to_currency(r.netto)}".html_safe) +
                              content_tag(:td, fattura) +
                              content_tag(:td, "#{r.evaso}/#{r.quantità}") +
                              content_tag(:td, "#{lnkstato}<br/><em>#{r.statoeditoriale}</em>".html_safe) +
                              content_tag(:td, r.note))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  
  def sbct_titles_info_deleted(record)
    dr=record.info_deleted_record
    return if dr.nil?
    res = []
    res << content_tag(:tr, content_tag(:td, '<b>Informazioni su titolo cancellato</b>'.html_safe, colspan:2))
    res << content_tag(:tr, content_tag(:td, 'Data cancellazione', class:'col-md-3') + content_tag(:td, dr['date_deleted'].to_date))
    res << content_tag(:tr, content_tag(:td, 'Cancellato da') + content_tag(:td, dr['deleted_by']))
    res << content_tag(:tr, content_tag(:td, 'Nota') + content_tag(:td, dr['notes']))
    res << content_tag(:tr, content_tag(:td, "Dettagli") + content_tag(:td, dr['data']))
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_titles_show_parent_title(record)
    res=[]
    record.sbct_titles.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.titolo, sbct_title_path(r))))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end
  
  def sbct_titles_show_title(record)
    res=[]
    # res << content_tag(:tr, content_tag(:td, 'Campo') + content_tag(:td, 'Valore'), class:'active')
    links_ok=nil
    if !record.manifestation_id.blank? and record.ean.blank?
      ean_links = sbct_titles_links_via_ean('',record.manifestation_id)
      res << content_tag(:tr, content_tag(:td, 'Clavis') + content_tag(:td, " <b>[#{ean_links.join(', ')}]</b>".html_safe))
      links_ok=true
    end
    record.attributes.keys.each do |k|
      next if record[k].blank?
      # next if ['utente'].include?(k)
      txt = record[k]
      if k == 'ean' and links_ok.nil?
        ean_links = sbct_titles_links_via_ean(txt,record.manifestation_id)
        txt = link_to(txt, sbct_titles_path("sbct_title[ean]":txt))
        res << content_tag(:tr, content_tag(:td, k.upcase) + content_tag(:td, "#{txt} - <b>[#{ean_links.join(', ')}]</b>".html_safe))
        next
      end
      next if k == 'crold_notes'
      next if k == 'utente'
      if k == 'parent_id'
        res << content_tag(:tr, content_tag(:td, "Serie") + content_tag(:td, link_to(record.parent_title.titolo, sbct_title_path(record.parent_id))))
        next
      end
      if k == 'prezzo'
        res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, number_to_currency(txt)))
      else
        if k=='id_titolo'
          if can? :edit, SbctTitle

            #if can? :manage, SbctTitle or current_user.id == record.created_by
            #  lnk = link_to("<b>Modifica titolo</b>".html_safe, edit_sbct_title_path(record.id), class:'btn btn-warning')
            #else
            #  lnk = ''.html_safe
            #end

            if can? :edit, SbctTitle and SbctTitle.libraries_select(current_user).size > 0
              lnk = link_to("<b>Modifica titolo</b>".html_safe, edit_sbct_title_path(record.id), class:'btn btn-warning')
            else
              lnk = ''.html_safe
            end

            
            # if !@current_list.nil? and ((can? :edit, SbctList or SbctTitle.user_roles(current_user).include?('AcquisitionStaffMember')) and (@current_list.owner_id.nil? or @current_list.owner_id == current_user.id)) or (!@current_list.nil? and !@current_list.owner_id.nil? and @current_list.owner_id == current_user.id)

            if !@current_list.nil? and (can? :edit, SbctList or !@current_list.assign_user_session(current_user, @current_list).nil?)
              
              if @sbct_title.sbct_lists.include?(@current_list)
                # lnk << link_to("<b>Rimuovi dalla lista #{@current_list.to_label}</b>".html_safe, sbct_title_path(record.id, toggle_list:@current_list.id), class:'btn btn-danger')
              else
                # lnk << link_to("<b>Aggiungi alla lista #{@current_list.to_label}</b>".html_safe, sbct_title_path(record.id, toggle_list:@current_list.id), class:'btn btn-success')
              end
              # lnk << link_to('[cambia lista]', sbct_lists_path(current_title_id:record))
              lnk << link_to('[cambia lista]', sbct_title_path(record,req:'chlist'))
            end
            # lnk << link_to('<b>Aggiungi copie</b>'.html_safe, new_sbct_item_path(id_titolo:record.id_titolo), class:'btn btn-warning') if can? :new, SbctItem and record.prezzo.to_i > 0 and SbctTitle.libraries_select(current_user).size > 0
            lnk << link_to('<b>Aggiungi copie</b>'.html_safe, new_sbct_item_path(id_titolo:record.id_titolo), class:'btn btn-warning') if can? :new, SbctItem  and SbctTitle.libraries_select(current_user).size > 0
            lnk << link_to('<b>Aggiungi copie dono</b>'.html_safe, new_sbct_item_path(id_titolo:record.id_titolo,nobudget:true), class:'btn btn-warning') if can? :manage, SbctItem
            lnk << link_to('<b>Deposito legale</b>'.html_safe, new_sbct_item_path(id_titolo:record.id_titolo,dl:true), class:'btn btn-warning') if can? :manage, SbctItem

            (
              upload_list = current_user.sbct_lista_caricamenti_default
              if !upload_list.nil?
                mypath = upload_sbct_lists_path(id_lista:upload_list.id,current_title_id:record)
                lnk << link_to("<b>Carica da XLS Leggere</b>".html_safe, mypath, class:'btn btn-warning')
              end
            )
            if record.sbct_items.size==0
              if can? :manage, SbctTitle
                lnk << link_to("<b>Cancella titolo</b>".html_safe, record, method: :delete, data: { confirm: 'Sicura di voler eliminare questo titolo?'},class:'btn btn-warning')
              else
                lnk << link_to("<b>Cancella titolo</b>".html_safe, record, method: :delete, data: { confirm: 'Confermi eliminazione di questo titolo?'},class:'btn btn-warning') if record.created_by==current_user.id
              end
            end
            res << content_tag(:tr, content_tag(:td, '') + content_tag(:td, lnk))
          end
        else
          if ['created_by','updated_by'].include?(k)
            res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, "#{User.find(txt).email} / user_id: #{txt}"))
          else
            tv = txt.class==ActiveSupport::TimeWithZone ? txt.to_date : txt
            if txt.class==ActiveSupport::TimeWithZone
              res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, tv))
            else
              # txt = link_to(tv, sbct_titles_path("sbct_title[#{k}]":txt))
              v = link_to(txt, sbct_titles_path("sbct_title[titolo]":"#{k}:#{txt}"))
              res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, v))
            end
            # res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, tv))
          end
        end
      end
    end
    if current_user.email=='seba'
      (
        c=record.collocazione_decentrata(@esemplari_presenti_in_clavis)
        res << content_tag(:tr, content_tag(:td, 'Collocazione', title:'Probabile collocazione a scaffale aperto, desunta dai dati catalografici') + content_tag(:td, c)) if !c.blank?
      )
    end
    if record.clavis_purchase_proposals.size > 0
      res << content_tag(:tr, content_tag(:td, 'Proposte acquisto lettori Clavis') + content_tag(:td, sbct_clavis_purchase_proposals(record.clavis_purchase_proposals)))
      if !record.manifestation_id.nil?
        txt = %Q{<span style='font-size:12px;'>&lt;a href="https://bct.comperio.it/opac/detail/view/sbct:catalog:#{record.manifestation_id}"&gt;Presente nel catalogo delle BCT&lt;/a&gt;</span>}.html_safe
        res << content_tag(:tr, content_tag(:td, "<span style='font-size:12px'>risposta da copiare e incollare</span>".html_safe) + content_tag(:td, txt))
      end
    end
    res << content_tag(:tr, content_tag(:td, sbct_libraries(record),colspan:2)) if user_session[:delivery_notes_mode].nil?
    # res << content_tag(:tr, content_tag(:td, link_to('Copie', sbct_items_path("sbct_item[id_titolo]":record.id_titolo),class:'btn btn-success')) + content_tag(:td, sbct_libraries(record)))
    res << content_tag(:tr, content_tag(:td, 'già in Clavis', title:'esclusi gli esemplari scartati') + content_tag(:td, sbct_presenti_in_clavis(@esemplari_presenti_in_clavis))) if @esemplari_presenti_in_clavis.size > 0
    res=content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_titles_show_short_title(record)
    res=[]
    # res << content_tag(:tr, content_tag(:td, 'Campo') + content_tag(:td, 'Valore'), class:'active')
    links_ok=nil
    if !record.manifestation_id.blank? and record.ean.blank?
      ean_links = sbct_titles_links_via_ean('',record.manifestation_id)
      res << content_tag(:tr, content_tag(:td, 'Clavis') + content_tag(:td, " <b>[#{ean_links.join(', ')}]</b>".html_safe))
      links_ok=true
    end
    record.attributes.keys.each do |k|
      next if record[k].blank?
      # next if ['utente'].include?(k)
      txt = record[k]
      if k == 'ean' and links_ok.nil?
        ean_links = sbct_titles_links_via_ean(txt,record.manifestation_id)
        txt = link_to(txt, sbct_titles_path("sbct_title[ean]":txt))
        res << content_tag(:tr, content_tag(:td, k.upcase) + content_tag(:td, "#{txt} - <b>[#{ean_links.join(', ')}]</b>".html_safe))
        next
      end
      next if k == 'crold_notes'
      next if k == 'utente'
      if k == 'parent_id'
        res << content_tag(:tr, content_tag(:td, "Serie") + content_tag(:td, link_to(record.parent_title.titolo, sbct_title_path(record.parent_id))))
        next
      end
      if k == 'prezzo'
        res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, number_to_currency(txt)))
      else
        if k=='id_titolo'
          if can? :edit, SbctTitle

            lnk = ''.html_safe

            
            if !@current_list.nil? and (can? :edit, SbctList or !@current_list.assign_user_session(current_user, @current_list).nil?)
              
              if @sbct_title.sbct_lists.include?(@current_list)
                # lnk << link_to("<b>Rimuovi dalla lista #{@current_list.to_label}</b>".html_safe, sbct_title_path(record.id, toggle_list:@current_list.id), class:'btn btn-danger')
              else
                # lnk << link_to("<b>Aggiungi alla lista #{@current_list.to_label}</b>".html_safe, sbct_title_path(record.id, toggle_list:@current_list.id), class:'btn btn-success')
              end
              # lnk << link_to('[cambia lista]', sbct_lists_path(current_title_id:record))
              lnk << link_to('[cambia lista]', sbct_title_path(record,req:'chlist'))
            end

            res << content_tag(:tr, content_tag(:td, '') + content_tag(:td, lnk))
          end
        else
          if ['created_by','updated_by'].include?(k)
            res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, "#{User.find(txt).email} / user_id: #{txt}"))
          else
            tv = txt.class==ActiveSupport::TimeWithZone ? txt.to_date : txt
            if txt.class==ActiveSupport::TimeWithZone
              res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, tv))
            else
              # txt = link_to(tv, sbct_titles_path("sbct_title[#{k}]":txt))
              v = link_to(txt, sbct_titles_path("sbct_title[titolo]":"#{k}:#{txt}"))
              res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, v))
            end
            # res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, tv))
          end
        end
      end
    end

    if record.clavis_purchase_proposals.size > 0
      res << content_tag(:tr, content_tag(:td, 'Proposte acquisto lettori Clavis') + content_tag(:td, sbct_clavis_purchase_proposals(record.clavis_purchase_proposals)))
      if !record.manifestation_id.nil?
        txt = %Q{<span style='font-size:12px;'>&lt;a href="https://bct.comperio.it/opac/detail/view/sbct:catalog:#{record.manifestation_id}"&gt;Presente nel catalogo delle BCT&lt;/a&gt;</span>}.html_safe
        res << content_tag(:tr, content_tag(:td, "<span style='font-size:12px'>risposta da copiare e incollare</span>".html_safe) + content_tag(:td, txt))
      end
    end

    res << content_tag(:tr, content_tag(:td, sbct_libraries(record),colspan:2)) if user_session[:delivery_notes_mode].nil?

    res=content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  
  # cpp sta per clavis purchase proposals
  def sbct_clavis_purchase_proposals(cpp)
    res = []

    # "https://sbct.comperio.it/index.php?page=Circulation.PatronViewPage&id=#{r.patron_id}"
    cpp.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.date_created.to_date, clavis_purchase_proposal_path(r.proposal_id), title:'Vedi dettagli proposta')) +
                              content_tag(:td, r.stato_proposta) +
                              content_tag(:td, link_to(r.patron_barcode, clavis_purchase_proposals_path(patron_id:r.patron_id), title:"Vedi proposte di #{r.patron_barcode}")) +
                              content_tag(:td, r.preferred_library)
                        )
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')    
  end

  def sbct_titles_db_originale(record)
    return nil if record.nil?
    res=[]
    # res << content_tag(:tr, content_tag(:td, 'Campo') + content_tag(:td, 'Valore'), class:'active')
    record.attributes.keys.each do |k|
      next if record[k].blank?
      txt = record[k]
      res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, txt))
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_libraries(record)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-1') +
                            content_tag(:td, 'Oper', class:'col-md-1') +
                            content_tag(:td, 'Data ins', class:'col-md-2') +
                            content_tag(:td, 'Prezzo', class:'col-md-1') +
                            content_tag(:td, 'Budget', class:'col-md-2') +
                            content_tag(:td, 'Ordine', class:'col-md-1') +
                            content_tag(:td, 'Stato', class:'col-md-1') +
                            content_tag(:td, 'Fornitore', class:'col-md-2') +
                            content_tag(:td, '', class:'col-md-1'), class:'success')
    cnt = 0
    if can? :update_order_status, SbctItem
      record.sbct_items.each do |r|
        cnt+=1
        if r.order_status=='N'
          st_opt = nil
        else
          if r.inviato=='t'
            st_opt = options_for_select(SbctOrderStatus.options_for_select(['A','N','O']), r.order_status)
          else
            st_opt = nil
          end
        end
        res << sbct_libraries_row(r, st_opt)
      end
    else
      record.sbct_items.each do |r|
        cnt+=1; res << sbct_libraries_row(r, nil)
      end
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-bordered')
    # content_tag(:table, res.join.html_safe, class:'table table-bordered')
  end

  def sbct_libraries_row(r,status_options)
    # h={A:'warning',N:'danger',O:'info'}

    begin
      trclass = h[r.order_status.to_sym]
    rescue
      trclass = ''
    end
    supplier = r.sbct_supplier.nil? ? '' : link_to(r.sbct_supplier.to_label,sbct_supplier_path(r.sbct_supplier.id))
    if can? :show, SbctOrder
      order_lnk = r.order_id.nil? ? '' : link_to(r.order_id,sbct_order_path(r.order_id), class:'btn btn-warning')
    else
      order_lnk = r.order_id.nil? ? '' : r.order_id
    end
    if r.clavis_library.siglabct.nil?
      library_name = r.clavis_library.to_label
      library_title = 'Senza sigla'
    else
      library_name = r.siglabib
      library_title = r.clavis_library.to_label
    end
    # return "test - scusate, fra qualche secondo torno a funzionare - opt: '#{status_options}' - #{trclass} #{library_name}"

    delete_lnk = ''
    confirm_lnk = ''
    if r.order_id.nil?
      if r.order_status.blank?
        orderstatus = String.new
      else
        orderstatus = String.new(r.order_status_label)
      end
      if can? :manage, SbctItem
        if r.order_status != 'A'
          # if r.strongness==1 and !current_user.role?('AcquisitionManager')
          if !r.strongness.blank? and r.strongness > 0 and !current_user.role?(['AcquisitionManager','AcquisitionStaffMember'])
            delete_lnk = %Q{<span title="Non cancellabile - inserito da utente #{r.created_by} / confermato da #{r.confirmed_by}">Non cancellabile</span>}.html_safe
          else
            if !r.strongness.blank? and r.strongness > 0
              lnktxt = "Cancella"
              lnktxt += " (inserito da #{r.created_by})" if !r.created_by.blank?
              lnktxt += " (confermato da #{r.confirmed_by})" if !r.confirmed_by.blank?
            else
              lnktxt = "Cancella"
            end
            delete_lnk = link_to(lnktxt, r, method: :delete, data: { confirm: 'Sicura di voler eliminare questa copia?'}, class:'btn btn-danger')
          end
        end
      else
        if current_user.id == r.created_by
          delete_lnk = link_to("Cancella (puoi perché è tuo)", r, method: :delete, data: { confirm: 'Sicura di voler eliminare questa copia?'}, class:'btn btn-danger')
        else
          if !user_session[:current_library].nil? and user_session[:current_library]==r.library_id and r.order_status=='S'
            delete_lnk = link_to("Cancella (per la tua biblioteca)", r, method: :delete, data: { confirm: 'Sicura di voler eliminare questa copia?'}, class:'btn btn-danger')
            if r.strongness.to_i == 1
              confirm_lnk = "<br/><hr/>Confermato da user #{r.confirmed_by}".html_safe
            else
              confirm_lnk = "<br/><hr/>#{link_to("Conferma acquisto", selection_confirm_sbct_item_path(r), method: :post, data: { confirm: 'Confermi volontà di acquistare? (sulla tua quota budget)'}, class:'btn btn-success')}".html_safe
            end
          end
        end
      end
    else
      # Esemplare con order_id
      if r.order_status.blank?
        orderstatus = r.order_status_label
      else
        # if r.data_arrivo.nil? or (r.data_arrivo == Time.now.to_date) or SbctTitle.user_roles(current_user).include?('AcquisitionManager')
        if r.data_arrivo.nil? or (r.data_arrivo == Time.now.to_date)
          if status_options.nil?
            orderstatus = "#{r.order_status_label}<br/>".html_safe
          else
            orderstatus = select_tag(:order_status, status_options, onchange:"change_item_order_status(this,#{r.id})")
          end
        else
          orderstatus = "#{r.order_status_label}<br/>".html_safe
        end
      end
    end
    # orderstatus << "Data arrivo: #{r.data_arrivo}" if !r.data_arrivo.blank?
    dataarrivo=''
    if !r.data_arrivo.blank?
      dataarrivo = "<br/>Data arrivo: #{r.data_arrivo}" 
      dataarrivo << "<span title='Segnato come arrivato da utente #{r.order_status_updated_by}'>(#{r.order_status_updated_by})</span>" if !r.order_status_updated_by.nil?
    end


    infouser = []
    infouser << %Q{<span title="inserito da">#{(r.created_by.nil? ? '' : User.find(r.created_by).email)}</span>}
    infouser << %Q{<span title="modificato da">#{(r.updated_by.nil? ? '' : User.find(r.updated_by).email)}</span>}

    infodat = []
    infodat << %Q{<span title="data inserimento">#{(r.date_created.nil? ? '' : r.date_created.to_date.to_s)}</span>}
    infodat << %Q{<span title="data modifica">#{(r.date_updated.nil? ? '' : r.date_updated.to_date.to_s)}</span>}
    infodat << "Note fornitore: #{r.note_fornitore}" if !r.note_fornitore.blank?
    infodat << "Note interne: #{r.note_interne}" if !r.note_interne.blank?
    if !r.event_id.blank?
      (
        ev = r.sbct_event
        tlink = "Tenere da parte per #{ev.creator.email}"
        infodat << content_tag(:span, %Q{#{link_to(tlink, sbct_event_path(ev.id), target:'_blank')}}.html_safe, title:"Evento: #{ev.to_label}")
      )
    end
    infodat << "Destinato a <b>#{r.dest_siglabib}</b>" if !r.dest_siglabib.blank?

    if current_user.role?('AcquisitionLibrarian')
      lnk = link_to(library_name, edit_sbct_item_path(r.id), class:'btn btn-warning')
    else
      if can? :update_order_status, SbctItem
        lnk = link_to(library_name, edit_sbct_item_path(r.id), class:'btn btn-warning')
      else
        lnk = library_name
      end
    end

    style =
      {
        :A=>"label label-success",
        :N=>"label label-warning",
        :O=>"label label-primary",
        :S=>"label label-default",
        :I=>"",
      }
    cssclass = r.order_status.blank? ? '' : style[r.order_status.to_sym]
    orderstatus = content_tag(:span, orderstatus, class:cssclass)
    # orderstatus = r.order_status_updated_by
    # dataordine = r.inviato? ? '' : 'in preparazione'

    if r.inviato.nil?
      dataordine=''
    else
      if r.inviato == 't'
        dataordine=''
      else
        orderstatus='Ordine in preparazione'
        dataordine=''
      end
    end
    if params[:from_clavis]=='true' and !@sbct_title.manifestation_id.nil? and !r.supplier_id.nil? and r.clavis_item_id.nil? and ['A','O'].include?(r.order_status)
      url = "https://sbct.comperio.it/index.php?page=Catalog.ItemInsertBulkPage&manId=#{@sbct_title.manifestation_id}&supplier_id=#{r.supplier_id}".html_safe
      supplier += "<br/>#{link_to('Accessionamento', url, class:'btn btn-success')}".html_safe
    else
      url = ClavisItem.clavis_url(r.clavis_item_id)
      supplier += "<br/>#{link_to(library_name, url, class:'btn btn-success', title:'Record in Clavis')}".html_safe if !r.clavis_item_id.nil?
      supplier += "<br/>#{link_to('cancella copia', r, method: :delete, data: { confirm: 'Confermi cancellazione copia?'}, class:'btn btn-danger')}".html_safe if (current_user.role?('AcquisitionManager') or current_user.role?('AcquisitionStaffMember')) and r.created_by.nil? and r.budget_id.nil?
    end

    budget_lnk = ''
    if r.sbct_budget.nil?
      budget_lnk = ''
    else
      budget_lnk = link_to(r.sbct_budget.label,sbct_budget_path(r.sbct_budget.id))
      if current_user.role?('AcquisitionManager') and r.order_status=='S'
        budget_lnk << "<br/>#{link_to('Cambio budget', assign_to_other_budget_sbct_item_path(r.id))}".html_safe
      end
    end

    content_tag(:tr, content_tag(:td, lnk, title:library_title) +
                     content_tag(:td, infouser.join('<br/>').html_safe) +
                     content_tag(:td, infodat.join('<br/>').html_safe) +
                     content_tag(:td, number_to_currency(r.prezzo)) +
                     content_tag(:td, budget_lnk) +
                     content_tag(:td, order_lnk) +
                     content_tag(:td, "#{orderstatus}#{dataarrivo}#{dataordine}".html_safe) +
                     content_tag(:td, supplier.html_safe) +
                     content_tag(:td, delete_lnk + confirm_lnk), id:"sbct_item_#{r.id}", class:trclass)
  end

  def sbct_clavis_libraries(bbb)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-2') +
                            content_tag(:td, 'Data inventariazione', class:'col-md-2'), class:'warning')
    bbb.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['label'], ClavisItem.clavis_url(r['item_id']))) +
                              content_tag(:td, r['inventory_date'], class:'col-md-1'), class:'success')
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-bordered')
  end

  def sbct_presenti_in_clavis(esemplari)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-1') +
                            content_tag(:td, 'Data inv.', class:'col-md-2') +
                            content_tag(:td, 'Collocazione', class:'col-md-2') +
                            content_tag(:td, 'Stato', class:'col-md-2') +
                            content_tag(:td, 'Sorgente', class:'col-md-2') +
                            content_tag(:td, 'Serie-Inv', class:'col-md-1'), class:'success')
    esemplari.each do |r|
      # inventory_date = r['inventory_date'].blank? ? to_date
      res << content_tag(:tr, content_tag(:td, link_to(r['siglabct'], ClavisItem.clavis_url(r['item_id']),
                                                       class:'btn btn-success'),title:r['label']) +
                              content_tag(:td, (r['inventory_date'].nil? ? '(data mancante)' : r['inventory_date'].to_date)) +
                              content_tag(:td, r['collocazione']) +
                              content_tag(:td, r['item_status']) +
                              content_tag(:td, r['item_source']) +
                              content_tag(:td, r['serieinv']), class:'warning')
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-bordered')
  end

  def sbct_titles_users(users)
    res = []
    users.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.id, edit_user_sbct_titles_path(user_id:r.id), class:'btn btn-warning')) +
                              content_tag(:td, r.username) +
                              content_tag(:td, r.to_label) +
                              content_tag(:td, r.role_names) +
                              content_tag(:td, r.this_user_roles))
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-striped')
  end
  
  def sbct_title_clavis_patrons(title)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Utente', class:'col-md-2') +
                            content_tag(:td, 'Data richiesta', class:'col-md-4') +
                            content_tag(:td, 'barcode', class:'col-md-4'), class:'success')

    title.clavis_patrons.each do |r|
      if r['patron_id'].blank?
        lnk="Lettore non trovato in Clavis: #{r.inspect}"
      else
        patron_label = "#{r['name']} #{r['lastname']}"
        lnk = link_to(patron_label, clavis_purchase_proposals_path(patron_id:r['patron_id']), target:'_blank')
      end
      res << content_tag(:tr, content_tag(:td, lnk, class:'col-md-2') +
                              content_tag(:td, r['data_richiesta_lettore'], class:'col-md-4') +
                              content_tag(:td, r['barcode'], class:'col-md-4'), class:'warning')
    end
    return '' if res.size==1
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def sbct_titles_quick_view(rec)
    res = []
    res << content_tag(:tr, content_tag(:td, rec.autore))
    res << content_tag(:tr, content_tag(:td, rec.titolo))
    res << content_tag(:tr, content_tag(:td, rec.editore))
    res << content_tag(:tr, content_tag(:td, rec.collana))
    res << content_tag(:tr, content_tag(:td, rec.prezzo))
    res << content_tag(:tr, content_tag(:td, rec.datapubblicazione))
    res << content_tag(:tr, content_tag(:td, rec.reparto))
    res << content_tag(:tr, content_tag(:td, rec.siglebct))
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_titles_breadcrumbs
    # return params.inspect if current_user.email=='seba'
    links=[]
    if SbctTitle.user_roles(current_user).include?('AcquisitionSupplier')
      links << "Situazione ordini per #{SbctSupplier.find_by_external_user_id(current_user.id).to_label}"
      # links << link_to("Modifica password", edit_user_registration_path)
      links << link_to("<b>[esci]</b>".html_safe, destroy_user_session_path, :method => :delete)
      return %Q{&nbsp;#{links.join('&nbsp; | &nbsp;')}}.html_safe
    end

    links << link_to('PAC', '/pac', {title:'Pagina di partenza per le Procedure Acquisti Coordinati'})
    if params[:controller]=='sbct_lists' and ['import','man','show','index','new','edit', 'upload','upload_from_clavis_shelf','do_order'].include?(params[:action])
      if !params[:selection_mode].blank?
        links << link_to('Selezione', sbct_titles_path(:selection_mode=>'S', id_lista:params[:id]))
      else
        links << link_to("Liste", sbct_lists_path(current_title_id:params[:current_title_id],req:params[:req]))
      end
      if !@sbct_list.id.nil?
        loop_list = @sbct_list.parent
        t1 = []
        while !loop_list.nil?
          t1 << link_to(loop_list.label, sbct_list_path(loop_list,current_title_id:params[:current_title_id],req:params[:req]))
          # links << link_to(loop_list.label, sbct_list_path(loop_list))
          loop_list = loop_list.parent
        end
        t1.reverse.each do |e|
          links << e
        end
        links << link_to(@sbct_list.label, sbct_list_path(@sbct_list,current_title_id:params[:current_title_id],req:params[:req]))
      end
      if params[:current_title_id].to_i > 0
        tit = SbctTitle.find(params[:current_title_id].to_i)
        links << link_to(tit.titolo, sbct_title_path(tit))
      end
    end
    if params[:action]=='lastins'
      links << link_to("Liste", sbct_lists_path(current_title_id:params[:current_title_id]))
    end
    if params[:controller]=='sbct_budgets' and ['show','index'].include?(params[:action])
      links << link_to('Budgets', sbct_budgets_path)
    end
    if params[:controller]=='sbct_presets'
      links << link_to('Scorciatoie', sbct_presets_path)
    end

    if params[:controller]=='sbct_l_event_titles'
      # links << link_to('Eventi', sbct_events_path(myevents:'S'))
      links << link_to('Eventi', sbct_events_path)
      links << link_to(@sbct_event.to_label, sbct_event_path(@sbct_event)) if !@sbct_event.nil?
      links << 'Convalida richieste'
    end

    
    if params[:controller]=='clavis_purchase_proposals' and ['show','index'].include?(params[:action])
      links << link_to('Proposte acquisto', clavis_purchase_proposals_path("clavis_purchase_proposal[status]":'A'))
    end

    
    if params[:controller]=='sbct_l_budget_libraries' and ['edit','index'].include?(params[:action])
      links << link_to('Budgets', sbct_budgets_path)
      if !@sbct_budget.nil?
        links << link_to(@sbct_budget.to_label, @sbct_budget)
      end
      links << link_to('Ripartizione', sbct_l_budget_libraries_path(budget_id:@sbct_budget.id)) if params[:action]=='edit'
    end



    
    if ['piurichiesti'].include?(params[:action])
      links << link_to('Titoli più richiesti', piurichiesti_sbct_titles_path)
    end
    if params[:controller]=='sbct_events'
      links << link_to('Eventi', sbct_events_path)
      links << link_to(@sbct_event.to_label, sbct_event_path) if !params[:id].nil?
    end

    if params[:controller]=='sbct_invoices' and ['show','index'].include?(params[:action])
      links << link_to('Fatture', sbct_invoices_path)
      if !@sbct_invoice.nil?
        links << link_to(@sbct_invoice.sbct_supplier.supplier_name, sbct_invoices_path(supplier_id:@sbct_invoice.sbct_supplier))
        links << link_to(@sbct_invoice.to_label, sbct_invoice_path)
      end
    end

    if params[:controller]=='sbct_items'
      links << link_to('Copie', sbct_items_path)
    end

    if params[:controller]=='sbct_orders' and ['show','index'].include?(params[:action])
      links << link_to('Ordini', sbct_orders_path(all:true))
      links << link_to(@sbct_supplier.to_label, sbct_orders_path(supplier_id:@sbct_supplier.id,all:true)) if !@sbct_supplier.nil?
      links << link_to(@sbct_order.label, sbct_order_path) if !@sbct_order.nil?
    end

    if params[:controller]=='sbct_suppliers' and ['show','index'].include?(params[:action])
      links << link_to('Fornitori', sbct_suppliers_path)
      links << link_to(@sbct_supplier.to_label, sbct_supplier_path) if !@sbct_supplier.nil?
    end

    if params[:controller]=='sbct_titles' and ['edit_user'].include?(params[:action])
      links << link_to("Utenti PAC", view_users_sbct_titles_path)
    end

    if params[:controller]=='sbct_titles' and ['show','edit'].include?(params[:action])
      links << link_to(@sbct_title.titolo, @sbct_title)
    end

    if params[:controller]=='sbct_titles' and ['index'].include?(params[:action])
      if !@sbct_list.nil?
        if !params[:id_lista].blank?
          links << link_to("Liste", sbct_lists_path)
        else
          links << link_to('Titoli', sbct_titles_path)
        end

        loop_list = @sbct_list.parent
        t1 = []
        while !loop_list.nil?
          t1 << link_to(loop_list.label, sbct_list_path(loop_list))
          # links << link_to(loop_list.label, sbct_list_path(loop_list))
          loop_list = loop_list.parent
        end
        t1.reverse.each do |e|
          links << e
        end
        links << link_to(@sbct_list.label, sbct_list_path(@sbct_list))


        
      end

      if !params[:selection_mode].blank?
        id_lista = @sbct_list.nil? ? params[:id_lista] : @sbct_list.id
        links << link_to('Selezione', sbct_titles_path(:selection_mode=>'S', id_lista:id_lista))
      else
        if !params[:id_lista].blank?
          # links << link_to("Liste d'acquisto", sbct_lists_path)
        else
          # links << link_to('Titoli', sbct_titles_path)
        end
      end
    end
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

  def sbct_titles_browse(record,ids)
    return if  ids.index(record.id).nil?
    p = record.browse_object('prev',ids)
    n = record.browse_object('next',ids)
    curpos = ids.index(record.id) + 1
    ccss = 'btn btn-info'
    ccss = 'label label-info'
    tot=ids.size
    lnks = []
    if !p.nil?
      lnks << link_to(content_tag(:span, '|<', class:ccss, title:"1 / #{tot}"), sbct_title_path(record.browse_object('first',ids)))
      lnks << link_to(content_tag(:span, ' < ', class:ccss), sbct_title_path(p))
    else
      lnks << content_tag(:span, '|<', class:ccss)
      lnks << content_tag(:span, ' < ', class:ccss)
    end
    if !n.nil?
      lnks << link_to(content_tag(:span, ' > ', class:ccss), sbct_title_path(n))
      lnks << link_to(content_tag(:span, '>|', class:ccss, title:"#{tot} / #{tot}"), sbct_title_path(record.browse_object('last',ids)))
    else
      lnks << content_tag(:span, ' > ', class:ccss)
      lnks << content_tag(:span, '>|', class:ccss)
    end
    content_tag(:span, "#{lnks.join('')} [#{curpos}/#{tot}]".html_safe, class:ccss)
  end

  def report_selezionati(user)
    begin
      u = SbctUser.find(user.id)
    rescue
      return ''
    end
    return if u.roles.first.name!='AcquisitionLibrarian'
    r=u.items_selection_report.first
    return if r['prezzo'].blank?
    link_to("#{number_to_currency(r['prezzo'])} (#{r['numcopie']} copie selezionate)", sbct_items_path(created_by:user.id,"sbct_item[order_status]":'S'))
  end

  def sbct_titles_analisi_liste(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Nome della lista', class:'col-md-1') +
                            content_tag(:td, 'Numero titoli', class:'col-md-2 text-left'), class:'success')
    records.each do |r|
      id_lista = r['id_lista'].to_i
      # lnk = link_to(r['count'], "/pac?fmt=analisi_liste&id_lista=#{id_lista}", class:'btn btn-success')
      lnk = r['count']
      res << content_tag(:tr, content_tag(:td, link_to(r['label'], sbct_list_path(id_lista))) +
                              content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end
  def sbct_titles_analisi_reparti(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Reparto', class:'col-md-1') +
                            content_tag(:td, 'Sottoreparto', class:'col-md-2 text-left') +
                            content_tag(:td, 'Numero titoli', class:'col-md-2 text-left'), class:'success')
    numtitoli = 0
    records.each do |r|
      numtitoli += r['numtitoli'].to_i
      # lnk = link_to(r['count'], "/pac?fmt=analisi_liste&id_lista=#{id_lista}", class:'btn btn-success')
      res << content_tag(:tr, content_tag(:td, r['reparto']) +
                              content_tag(:td, r['sottoreparto']) +
                              content_tag(:td, r['numtitoli']))
    end
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, '', class:'col-md-2 text-left') +
                            content_tag(:td, numtitoli, class:'col-md-2 text-left'), class:'success')

    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sbct_titles_analisi_biblioteche(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-1') +
                            content_tag(:td, 'Numero copie', class:'col-md-2') +
                            content_tag(:td, 'Importo', class:'col-md-9'), class:'success')
    importo_totale=0.0
    numcopie = 0
    records.each do |r|
      importo_totale += r['importo'].to_f
      numcopie += r['numcopie'].to_i
      res << content_tag(:tr, content_tag(:td, r['siglabib']) +
                              content_tag(:td, r['numcopie']) +
                              content_tag(:td, r['importo']))
    end
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, numcopie, class:'col-md-2') +
                            content_tag(:td, number_to_currency(importo_totale.round(2)), class:'col-md-9'), class:'success')

    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def delivery_notes_controllo_prezzi
    sql=%Q{select t.titolo,t.id_titolo,rl.prezzo as prezzo_in_bolla,t.prezzo from sbct_acquisti.report_logistico rl join sbct_acquisti.titoli t using(id_titolo) where rl.prezzo != t.prezzo;}
    res = []
    SbctTitle.find_by_sql(sql).each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.titolo, sbct_title_path(r.id_titolo), target:'_new')) +
                              content_tag(:td, r.prezzo_in_bolla) +
                              content_tag(:td, r.prezzo))
    end
    if res.size>0
      header=content_tag(:tr, content_tag(:td, 'Titolo', class:'col-md-6') +
                              content_tag(:td, 'Prezzo in bolla', class:'col-md-1') +
                              content_tag(:td, 'Prezzo in PAC', class:'col-md-5'))
      content_tag(:table, header + res.join.html_safe, class:'table table-striped')
    else
    end
    
  end
  
end
