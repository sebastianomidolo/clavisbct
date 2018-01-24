module TalkingBooksHelper
  def talking_books_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.titolo, talking_book_path(r))) +
                         content_tag(:td, r.n))
    end
    content_tag(:table, res.join.html_safe)
  end

  def talking_books_index_editable(records)
    res=[]
    records.each do |r|
      f=r.d_objects_folder_id
      img = f.nil? ? '' : link_to(image_tag('http://bctwww.comperio.it/static/libroparlato_scaricabile.jpg'), d_objects_folder_path(f))
      res << content_tag(:tr, content_tag(:td, link_to(r.n, edit_talking_book_path(r))) +
                              content_tag(:td, "#{r.cd} CD") +
                              content_tag(:td, img) +
                              content_tag(:td, link_to(r.titolo, talking_book_path(r))) +
                              content_tag(:td, r.digitalizzato))
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

  def talking_book_show_record(record)
    res = []
    res << content_tag(:h3,%Q{#{record.main_entry}<em>#{record.titolo}</em>.}.html_safe)
    href=nil
    if !record.d_objects_folder_id.nil?
      href=File.join('https://bctwww.comperio.it/tbda',File.basename(record.zip_filepath)) if !record.zip_filepath.nil?
    end
    ad=[]
    ad << "#{record.abstract}." if !record.abstract.blank?
    ok=false
    if !record.cd.nil? and record.da_inserire_in_informix=='0'
      ad << content_tag(:div, "Codice cd mp3: CD #{record.n}.", :class=>'codice')
      ok=true
    end
    if !record.cassette.nil?
      ad << content_tag(:div, "Codice cassette: #{record.n}, #{record.cassette} cassette.", :class=>'codice')
      ok=true
    end
    ad << content_tag(:div, "Collocazione: #{record.n} (id #{record.id})") if ok==false

    ad << link_to("Scarica #{record.n}", href) if !href.nil?
    ad << content_tag(:div, "Data inserimento: #{record.data_collocazione}")
    res << content_tag(:div, ad.join("\n").html_safe)
    # res << talking_book_opac(record)
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
      lnk="http://#{request.host_with_port}/" + download_mp3_talking_book_path(record, :mid => mid, :dng_user => params[:dng_user], :ac => access_control_key)
      res << image_tag("http://#{request.host_with_port}/assets/icona_download01.gif?mid=#{mid}", style: 'padding: 4px')
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
    else
      res << "file zip audio non presente"
    end
    content_tag(:pre, res.join("\n"))
  end
end
