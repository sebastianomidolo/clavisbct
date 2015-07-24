# -*- coding: utf-8 -*-
# lastmod 20 febbraio 2013

module ClavisManifestationsHelper
  def clavis_manifestation_view(record)
    r=[]
    # lnk=content_tag(link_to(record.title, record.clavis_url))
    lnk=link_to(record.title, record.clavis_url(:opac))
    r << content_tag(:div, content_tag(:b, lnk))
    if record.bib_level=='s'
      r << content_tag(:div, record.bid)
      if record.bid_source=='SBN'
        ic=record.kardex_adabas_issues_count
        r << content_tag(:div, link_to("Consulta Kardex Adabas 2011 (#{ic} fascicoli)",
                                       record.kardex_adabas_2011_url)) if ic>0
      end
    end
    r << content_tag(:div, link_to('opac.sbn.it', record.iccu_opac_url)) if !record.iccu_opac_url.nil?
    r.join.html_safe
  end

  def clavis_manifestation_show_items(record)
    res=[]
    res << content_tag(:tr, content_tag(:th, 'Id biblioteca') +
                       content_tag(:th, 'Item Id') +
                       content_tag(:th, 'Collocazione') +
                       content_tag(:th, 'Serie-Inventario') +
                       content_tag(:th, 'Item media'))

    record.clavis_items(order: [:owner_library_id,:inventory_value,:inventory_number]).each do |r|
      res << content_tag(:tr, content_tag(:td, r.owner_library_id) +
                         content_tag(:td, r.id) +
                         content_tag(:td, r.collocazione) +
                         content_tag(:td, r.inventario) +
                         content_tag(:td, r.item_media))
    end
    content_tag(:table, res.join.html_safe, width: '100%')
  end

  def clavis_manifestation_opac_preview(record)
    mid = record.class==ClavisManifestation ? record.id : record
    %Q{<iframe src="http://bct.comperio.it/opac/detail/badge/sbct:catalog:#{mid}?height=300&showabstract=1&coversize=normal" frameborder="0" width="600" height="300"></iframe>}.html_safe
  end

  def clavis_manifestations_shortlist(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'BID') +
                       content_tag(:td, 'level') +
                       content_tag(:td, 'type') +
                       content_tag(:td, 'created') +
                       content_tag(:td, 'modif') +
                       content_tag(:td, 'sbnsync') +
                       content_tag(:td, '') +
                       content_tag(:td, '') +
                       content_tag(:td, ''))

    # content_tag(:td, r.last_sbn_sync.blank? ? 'never' : l.last_sbn_sync) +

    records.each do |r|
      sbnsync=r.last_sbn_sync.blank? ? '' : r.last_sbn_sync.to_date

      tit=r.title.blank? ? '[vedi titolo]' : r.title[0..80]
      res << content_tag(:tr, content_tag(:td, r.thebid) +
                         content_tag(:td, r.bib_level) +
                         content_tag(:td, r.bib_type) +
                         content_tag(:td, r.created_by) +
                         content_tag(:td, r.modified_by) +
                         content_tag(:td, sbnsync) +
                         content_tag(:td, link_to('[opac]', r.clavis_url(:opac), :target=>'_blank')) +
                         content_tag(:td, link_to('[edit]', r.clavis_url(:edit), :target=>'_blank')) +
                         content_tag(:td, link_to(tit, r.clavis_url, :target=>'_blank')))
    end
    content_tag(:table, res.join.html_safe)
  end


  def clavis_manifestations_perbid
    sql="select bid_source,count(*) from clavis.manifestation where bib_level in('m','c','s') group by bid_source order by bid_source;"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      if r['bid_source'].blank?
        r['bid_source']='null'
        txt='[missing]'
      else
        txt=r['bid_source']
      end
      res << content_tag(:tr, content_tag(:td, r['count']) +
                         content_tag(:td, txt) +
                         content_tag(:td, link_to('collane', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'c'))) +
                         content_tag(:td, link_to('monografie', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'m'))) +
                         content_tag(:td, link_to('seriali', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'s'))) +
                         content_tag(:td, link_to('tutto', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source']))))
    end
    res << content_tag(:td, link_to('polo bct', shortlist_clavis_manifestations_url(:bid_source=>'SBNBCT', :polo=>'BCT')))
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestations_oggbibl
    sql="select value_key,value_label,value_class from clavis.lookup_value where value_language='it_IT' AND value_class ~* '^OGGBIBL_' order by value_key"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      # http://clavisbct.selfip.net/clavis_manifestations/shortlist?bib_type=a02
      res << content_tag(:tr, content_tag(:td, r['value_key']) +
                         content_tag(:td, link_to(r['value_label'], shortlist_clavis_manifestations_url(:bib_type=>r['value_key']))) +
                         content_tag(:td, link_to("#{r['value_key']} (senza bid)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'null'))) +
                         content_tag(:td, link_to("#{r['value_key']} (LOC)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'LOC'))) +
                         content_tag(:td, link_to("#{r['value_key']} (UKLIB)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'UKLIB'))) +
                         content_tag(:td, link_to("#{r['value_key']} (FRLIB)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'FRLIB'))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestations_attachments_summary(attachment_category)
    cond=attachment_category.blank? ? '' : "where ac.code=#{ActiveRecord::Base.connection.quote(attachment_category)}"
    sql=%Q{select trim(cm.title) as title,cm.manifestation_id,ac.label,count(*) from attachments a join attachment_categories ac on(a.attachment_category_id=ac.code) join clavis.manifestation as cm on(a.attachable_id=cm.manifestation_id) #{cond} group by cm.title,cm.sort_text,cm.manifestation_id,ac.label order by ac.label desc,lower(trim(cm.sort_text));}
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    cnt=0
    pg.each do |r|
      cnt+=1
      lnk="http://bct.comperio.it/opac/detail/view/sbct:catalog:#{r['manifestation_id']}"
      res << content_tag(:tr, content_tag(:td, cnt) +
                         content_tag(:td, link_to(r['title'], lnk)) +
                         content_tag(:td, r['label']) +
                         content_tag(:td, link_to('vedi',
                  clavis_manifestation_path(r['manifestation_id'], :dng_user=>params[:dng_user]))) +
                         content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestation_pdf_links(record,ac_key=nil)
    res=[]
    n=0
    record.attachments_generate_pdf(true).each do |fname|
      ac=access_control_key
      # return "ac: #{ac} - params[:ac]: #{params[:ac]}"
      # res << content_tag(:tr, content_tag(:td, ac))
      # next if ac.nil? or ac!=params[:ac]
      params[:ac]=ac_key if params[:ac].blank? and !ac_key.nil?
      next if ac.nil? or ac!=params[:ac]
      dng_session = DngSession.find_by_params_and_request(params,request)
      if !dng_session.check_service('download_pdf',params,request,record)
        return '[file pdf non accessibile]'
      end
      text=n
      dg=Digest::MD5.hexdigest(fname)
      lnk=link_to("Scarica file in formato PDF: pdf_file_#{n+1}","http://#{request.host_with_port}#{attachments_clavis_manifestation_path(record, :format=>'pdf', :fkey=>dg,:filenum=>n, :ac=>ac, :dng_user=>params[:dng_user])}")
      res << content_tag(:tr, content_tag(:td, lnk) +
                         content_tag(:td, number_to_human_size(File.size(fname))))
      n+=1
    end
    # return "vuoto" if res.blank?
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestation_show_attachments(record,params,request,dng_session)
    return [nil,nil] if record.attachments.size==0
    content=tabtitle=testo_avviso=nil
    if ['i05','i02'].include?(record.bib_type)
      # Libro parlato
      # tabtitle="Audio libro parlato #{record.bib_type}"
      # return '' if dng_session.nil?
      tabtitle="Audio libro parlato"
      if dng_session and dng_session.expired?
        content=%Q{La sessione di lavoro risulta scaduta - <a href="/Security/logout">Effettuare un nuovo accesso</a>}
      else
        if dng_session and dng_session.check_service('talking_book',params,request)
          content = talking_book_opac_presentation(record,true)
        else
          uname = dng_session.nil? ? 'Gentile utente' : dng_session.patron.appellativo
          content="#{uname}, Lei non risulta iscritto al Servizio del libro parlato: pertanto non ha accesso alle registrazioni audio presenti nel nostro archivio. Maggiori informazioni sono disponibili alla pagina "
          content+=content_tag(:span, link_to('\"Condizioni di iscrizione e prestito\"', 'http://www.comune.torino.it/cultura/biblioteche/lettura_accessibile/libriparlati.shtml'))
          content+=content_tag(:br)
          content += talking_book_opac_presentation(record,false)
        end
      end
    else
      x=record.attachments.first.attachment_category
      x = x.nil? ? 'Allegati' : x.label
      tabtitle="#{x}"
      testo_avviso="Informazione: il contenuto di questa pagina, inserito a titolo sperimentale, potrebbe contenere errori e cambiare senza preavviso"
      # Attenzione, la chiamata "sicura" sarebbe questa:
      # content = clavis_manifestation_pdf_links(record)
      # Ma per far funzionare le cose, uso questa:
      content = clavis_manifestation_pdf_links(record, access_control_key)
      # La cosa giusta sarebbe che la chiamata da javascript includa il parametro ac=???
      # nell'url, cosa che al momento (ottobre 2013) non è possibile perché il valore di "ac"
      # dovrebbe essere incluso nella pagina fornita da Comperio in base al contesto.
      # Per ora ci accontentiamo di un codice meno sicuro, nel senso che con molta fantasia
      # un utente potrebbe riuscire a ricavare l'indirizzo corretto per scaricare un pdf
      # pur non avendone i diritti... ma non si tratta di conti bancari per cui al momento va bene così
      # In ogni caso, quando la sessione utente scade, il link al pdf viene comunque invalidato

      content+=content_tag(:div, attachments_render(record.attachments))

    end
    return [nil,nil] if content.blank?
    [tabtitle,content_tag(:span, testo_avviso) + content_tag(:div, content.html_safe)]
  end


  def clavis_manifestations_periodici_ordini(records)
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
        item_id,issue_status,giorni_ritardo,data_arrivo,atteso_per,invoice_id=f.split
        items_info[issue_status]=[] if items_info[issue_status].nil?
        items_info[issue_status] << [item_id,giorni_ritardo,data_arrivo,atteso_per]
        if invoice_id!='0'
          # fatture << %Q{<div class="alert alert-success">#{link_to("Fattura in Clavis", "http://sbct.comperio.it/index.php?page=Acquisition.InvoiceViewPage&id=#{invoice_id}", class: 'alert-link', target: '_blank')} su esemplare #{link_to(item_id,ClavisItem.clavis_url(item_id,:edit))} (#{hstatus[issue_status]})</div>}
        end
      end
      items_info.each_pair do |k,v|
        if v.size==1
          item_id,ritardo,data_arrivo,atteso_per=v.first
          lnk=link_to(hstatus[k],ClavisItem.clavis_url(item_id,:edit))
          if ritardo.to_i>0 and ['M','N','P'].include?(k)
            # info << content_tag(:span, "#{lnk} (#{ritardo} giorni ritardo)".html_safe, class: 'alert alert-danger')
            info << content_tag(:b, "#{lnk} (#{ritardo} giorni ritardo)".html_safe)
          else
            # info << "#{lnk} (previsto tra #{ritardo.to_i.abs} giorni)"
            # info << "#{lnk}"

            if ['N','P'].include?(k)
              info << content_tag(:b, "#{lnk} (#{atteso_per})".html_safe)
            else
              arrivo=data_arrivo=='-' ? '' : " (#{data_arrivo})"
              info << content_tag(:b, "#{lnk}#{arrivo}".html_safe)
            end
          end
        else
          info << "#{hstatus[k]} (#{v.size} esemplari)"
        end

      end
      clavis_subscription=''
      if !r['manifestation_id'].blank?
        clavis_subscription=r['subscription_id'].blank? ? link_to('[aggiungi abbonamento]',ClavisManifestation.clavis_url(r['manifestation_id'],:add_subscription)) : link_to('[vedi abbonamento]',ClavisManifestation.clavis_subscription_url(r['subscription_id']))
      end
      if r['numero_fattura'].blank? and !r['ordnum'].blank?
        textbox=%Q{#{content_tag(:div,r['titolo'])}
        #{
          content_tag(:div, 'Non fatturato', class: 'alert alert-danger') +
          content_tag(:div, ordini_dettaglio_ordine(r))
         }
        }
      else
        textbox=%Q{#{content_tag(:div,r['titolo'])}
        #{
          content_tag(:div, ordini_dettaglio_ordine(r))
         }
        }
      end
      if !@ordine.nil? and @ordine.library_id.nil?
        bib="<br/>#{content_tag(:b,r['library'])}"
      else
        bib=''
      end
      lnktext="#{r['title']}<br/>#{clavis_subscription}#{bib}".html_safe
      in_clavis=r['manifestation_id'].blank? ? content_tag(:div, 'Manca manifestation_id', class: 'alert alert-danger') : link_to(lnktext,ClavisManifestation.clavis_url(r['manifestation_id']))
      res << content_tag(:tr, content_tag(:td, "#{r['id']}") +
                         content_tag(:td, textbox.html_safe, :style=>'width: 30%') +
                         content_tag(:td, in_clavis, :style=>'width: 30%') +
                         content_tag(:td, fatture.join('</br>').html_safe) +
                         content_tag(:td, info.join('</br>').html_safe))

      # invoice=fattura.nil? ? 'non fatturato': 
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end


end
