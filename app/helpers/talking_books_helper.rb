# coding: utf-8

module TalkingBooksHelper

  def talking_books_index(records)
    res=[]
    records.each do |r|
      # tit = r.respons.blank? ? r.titolo : "#{r.titolo} / #{r.respons}"
      intest = r.intestatio.nil? ? '' : "#{r.intestatio.sub(/\.$/, '')}. "
      tit = r.respons.blank? ? r.titolo : "#{intest}#{r.titolo}"
      disp = talking_book_disponibile(r)
      lnk = content_tag(:h4, content_tag(:b, link_to(tit, "https://#{request.host_with_port}#{talking_book_path(r)}"))) + disp.html_safe
      res << content_tag(:tr, content_tag(:td, lnk, class:'col-md-10'))
    end
    content_tag(:div, content_tag(:table, res.join("\n").html_safe, :class=>'table table-striped'),
                :class=>'table-responsive')
  end

  def talking_books_listatitoli(records)
    res=[]
    records.each do |r|
      lnk=r.n
      if !r.d_objects_folder_id.nil?
        href=File.join('https://bctwww.comperio.it/tbda',File.basename(r.zip_filepath)) if !r.zip_filepath.nil?
        lnk = link_to("Scarica #{r.n}", href)
      end
      res << content_tag(:tr, content_tag(:td, r.intestatio) +
                              content_tag(:td, lnk) +
                              content_tag(:td, link_to(r.titolo, ClavisManifestation.clavis_url(r.manifestation_id,:opac)) + "<br/>#{r.abstract}".html_safe))
    end
    content_tag(:table, content_tag(:tbody, res.join.html_safe), id:'listatitoli')
  end

  def talking_books_index_editable(records)
    res=[]
    records.each do |r|
      tit = r.respons.blank? ? r.titolo : "#{r.titolo} / #{r.respons}"
      f=r.d_objects_folder_id
      img = f.nil? ? '' : link_to(image_tag('https://bctwww.comperio.it/static/libroparlato_scaricabile.jpg'), d_objects_folder_path(f))
      disp = talking_book_disponibile(r)
      lnk = "#{link_to(tit, edit_talking_book_path(r))}#{disp}".html_safe
      res << content_tag(:tr, content_tag(:td, r.n) +
                              content_tag(:td, img) +
                              content_tag(:td, lnk) +
                              content_tag(:td, r.digitalizzato))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def talking_book_disponibile_editable(record)
    res = []
    df = record.descr_fisica.split('|'), coll = record.collocations.split('|'), i = 0
    record.item_ids.split('|').each do |e|
      res << content_tag(:li, "Item: #{link_to(coll[i], ClavisItem.clavis_url(e))} (descrizione fisica: #{df[i]})".html_safe)
      i += 1
    end
    res << content_tag(:li, "Scaricabile") if !record.d_objects_folder_id.blank?
    "<br/>#{content_tag(:ul, res.join("\n").html_safe)}"
  end

  def talking_book_disponibile(record)
    res = []
    df = record.descr_fisica.split('|'), coll = record.collocations.split('|'), visib = record.opac_visibilities, i = 0
    record.item_ids.split('|').each do |e|
      next if visib[i]=='0'
      str = coll[i].match(/CD/i).nil? ? "cassette. Codice: <b>#{coll[i]}</b>" : "CD. Codice: <b>#{coll[i]}</b>"
      res << content_tag(:li, "Disponibile su #{str}".html_safe)
      i += 1
    end
    res << content_tag(:li, "Scaricabile") if !record.d_objects_folder_id.blank?
    # res << content_tag(:li, record.opac_visibilities)
    "<br/>#{content_tag(:ul, res.join("\n").html_safe)}"
  end


  def talking_book_clavis_items(record)
    res = []
    record.clavis_items.each do |r|
      cm = r.clavis_manifestation
      res << content_tag(:tr, content_tag(:td, link_to(r.title, r.clavis_url)) +
                              content_tag(:td, r.manifestation_id) +
                              content_tag(:td, r.opac_visible==1 ? 'Visibile in Opac' : 'Non visibile in Opac') +
                              content_tag(:td, cm.unimarc_field(215,'a')) +
                              content_tag(:td, r.collocation))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def talking_book_clavis_items_public(record)
    res = []
    record.clavis_items.each do |r|
      next if !r.loan_class =~ /^B/
      res << content_tag(:tr, content_tag(:td, r.la_collocazione) +
                              content_tag(:td, r.id) +
                              content_tag(:td, r.collocation))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end


  def talking_book_show(record)
    res=[]

    record.attributes.keys.each do |k|
      next if record[k].blank?
      lnk = k=='manifestation_id' ? clavis_manifestation_opac_preview(record[k]) : record[k]
      res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe)
  end

  def talking_book_edit(form,record)
    res=[]
    fields={
      titolo: ['Titolo',:text],
      n: ['Collocazione',:string],
      intestatio: 'Intestazione principale',
      respons: 'Indicazione di responsabilità',
      edizione: 'Edizione',
      editore: 'Editore',
      collana: 'Collana',
      isbn: 'ISBN',
      abstract: ['Abstract', :text],
      cassette: ['Numero di cassette', :integer],
      chiave: 'Chiave di ordinamento intestazione principale',
      ordine: 'Chiave ordinamento titolo',
      data_collocazione: ['Data di collocazione',:date],
      data_ritiro: ['Data di ritiro',:date],
      data_consegna: ['Data di consegna',:date],
      utente: 'Utente (che ha in prestito il libro?)',
      digitalizzato: ['Data di digitalizzazione', :date],
      cd: ['Numero di CD',:integer],
      manifestation_id: ['Numero di record in Clavis (manifestation_id)',:integer],
      non_disponibile: ['Non disponibile', :boolean],
      talking_book_reader_id: ['Lettore (ref)', :association],
      lettore: 'Lettore (formato testo, secondo la struttura in Access)',
    }
    fields.keys.each do |k|
      label, as_value = fields[k]
      as_value = :string if as_value.blank?
      # res << content_tag(:p, "k=#{k} - label: #{label} - as_value: #{as_value}")
      if as_value == :date
        f=form.input k.to_sym, label:label, as: as_value, :include_blank => true
        res << content_tag(:p, f)
      else
        if k == :talking_book_reader_id
          f=form.association :talking_book_reader, collection:TalkingBookReader.order(:cognome), include_blank:true, label:label
        else
          if k == :lettore
            res << content_tag(:p, "<b>#{label}: #{record[k]}</b>".html_safe)
            next
          else
            input_html = as_value==:text ? {cols: 80, rows: 3} : {}
            f=form.input k.to_sym, label:label, as: as_value, input_html: input_html
          end
        end
        res << content_tag(:pre, f)
      end
    end
    content_tag(:div, res.join.html_safe)
  end

  def talking_book_opac(record)
    return '' if record.manifestation_id.nil?
    lnk=clavis_manifestation_path(record.manifestation_id)
    res=[]
    res << link_to("Vedi manifestation #{record.manifestation_id}",lnk)
    res << content_tag(:div, clavis_manifestation_opac_preview(record.manifestation_id))
  end

  def talking_book_extra_data(record)
    res=[]

    fields=[
            :intestatio,
            :abstract
           ]

    fields.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe)
    res
  end

  def talking_book_available_items(record)
    res=[]
    record.clavis_items.each do |r|
      next if !r.loan_class =~ /^B/ or r.opac_visible != 1
      str = r.collocation.match(/CD/i).nil? ? "cassette. Codice: <b>#{r.collocation}</b> - #{record.cassette} cassette" : "CD. Codice: <b>#{r.collocation}</b>"
      res << content_tag(:li, "Disponibile su #{str}".html_safe)
    end
    res == [] ? '' : content_tag(:ul, res.join("\n").html_safe)
  end

  def talking_book_show_record(record)
    res = []
    res << content_tag(:h3,%Q{#{record.main_entry}<em>#{record.titolo}</em>.}.html_safe)
    href=nil
    if !record.d_objects_folder_id.nil?
      href=File.join('https://bctwww.comperio.it/tbda',File.basename(record.zip_filepath)) if !record.zip_filepath.nil? and File.exists?(record.zip_filepath)
    end
    ad=[]
    ad << "<p>#{record.abstract}</p>" if !record.abstract.blank?
    ad << talking_book_available_items(record)
    ad << button_to("Scarica il libro".html_safe, href, method:'get') if !href.nil?
    res << content_tag(:div, ad.join("\n").html_safe)
    content_tag(:div, res.join.html_safe,  :class=>'scheda_libro_parlato')
  end

  def talking_book_opac_presentation(clavis_manifestation,authorized)
    record = clavis_manifestation.talking_book
    res=[]
    if !record.nil? and !record.abstract.blank?
      res << content_tag(:div, content_tag(:div, content_tag(:b, "Il libro in sintesi (#{record.collocazione})"),
                                           class: 'panel-heading') +
                         content_tag(:div, record.abstract, class: 'panel-body'), class: 'panel panel-info')
    end
    if !record.nil? and !access_control_key.blank? and authorized
      mid=clavis_manifestation.manifestation_id
      lnk="https://#{request.host_with_port}/" + download_mp3_talking_book_path(record, :mid => mid, :dng_user => params[:dng_user], :ac => access_control_key)
      res << image_tag("https://#{request.host_with_port}/assets/icona_download01.gif?mid=#{mid}", style: 'padding: 4px')
      res << link_to(content_tag(:span, 'Scarica audio mp3 completo', class: "badge"), lnk)

      if clavis_manifestation.attachments.size>0
        #res << '<br/>'
        #res << image_tag("http://#{request.host_with_port}/assets/icona_ascolto.gif?mid=#{mid}", style: 'padding: 4px')
        #res << content_tag(:span, 'Ascolta in streaming')
        # content_tag(:span, clavis_manifestation.title, :class=>'label label-default')
        # content_tag(:span, ' in streaming')
        # res << content_tag(:button, access_control_key, :class=>'btn')
        #res << content_tag(:div, attachments_render(clavis_manifestation.attachments))
      end
    else
      # res << content_tag(:div, d_objects_render(clavis_manifestation.audioclips))
      # res << content_tag(:div, clavis_manifestation.id)
    end

    content_tag(:div, res.join.html_safe)
  end

  def talking_book_view_mp3_files(record)
    return nil if record.zip_filepath.blank?
    res=[]
    if File.exists?(record.zip_filepath)
      res << record.zip_filepath
      fsize=File.size(record.zip_filepath)
      res << "Dimensioni file: #{number_to_human_size(fsize)} (#{fsize} bytes)"
      res << "Data del file: #{File.ctime(record.zip_filepath)}"
      res << link_to("<b>[Cancella file zip (da realizzare)]</b>".html_safe, edit_talking_book_path(record), confirm:'Confermi cancellazione file zip?')
    else
      res << "file zip audio non presente"
      res << link_to("<b>[Genera file zip (da realizzare)</b>]".html_safe, edit_talking_book_path(record), confirm:'Confermi generazione file zip?')
    end
    content_tag(:pre, res.join("\n").html_safe)
  end


  def talking_books_breadcrumbs
    # return params.inspect
    links=[]
    links << link_to('Servizio del Libro Parlato', 'https://bct.comune.torino.it/programmi-progetti/programma/il-servizio-del-libro-parlato')
    if params[:controller]=='talking_books' and ['index','show','edit','check'].include?(params[:action])
      links << link_to('Catalogo dei libri parlati', talking_books_path)
    end
    if params[:controller]=='talking_books' and ['check_duplicates','digitalizzati_non_presenti','opac_edit_intro','stats'].include?(params[:action])
      links << link_to('Catalogo dei libri parlati', talking_books_path)
      links << link_to('Admin', check_talking_books_path)
    end


    if params[:controller]=='talking_book_readers' and ['check','index','edit','new','show'].include?(params[:action])
      links << link_to('Catalogo dei libri parlati', talking_books_path)
      links << link_to('Admin', check_talking_books_path)
      if !params[:id].blank?
        links << link_to('Volontari', talking_book_readers_path)
      end
    end
 
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

end
