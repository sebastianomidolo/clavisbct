module ProculturaHelper

  def procultura_archivi_old
    r=[]
    r << content_tag(:tr, content_tag(:td, 'Nome archivio') +
                       content_tag(:td, 'Numero schede'))

    ProculturaArchive.list.each do |e|
      lnk=procultura_make_link(procultura_folders_path(:archive_id=>e['id']))
      r << content_tag(:tr, content_tag(:td, link_to(e['name'], lnk)) +
                       content_tag(:td, e['count']))
    end
    content_tag(:table, r.join.html_safe)
  end

  def procultura_archivi
    r=[]
    ProculturaArchive.list.each do |e|
      lnk=procultura_make_link(procultura_folders_path(:archive_id=>e['id']))
      r << content_tag(:li, link_to("Schede del catalogo " + e['name'].downcase, lnk) + " (#{e['count']})")
    end
    content_tag(:ul, r.join.html_safe)
  end

  def procultura_cards_singole_schede(folder_or_array_of_cards)
    cards = folder_or_array_of_cards.class==ProculturaFolder ? folder_or_array_of_cards.cards : folder_or_array_of_cards
    r=[]
    cnt=0
    prec=nil
    cards.each do |c|
      cnt=0 if prec!=c.intestazione
      cnt+=1
      # lnk=procultura_make_link(procultura_card_path(c, :format=>:jpg))
      lnk="http://clavisbct.comperio.it/procultura_cards/#{c.id}.jpg"
      if cnt==1
        text=c.intestazione
      else
        text="#{c.intestazione} (#{cnt})"
      end
      if c.respond_to?('archive_name')
        spec=" <b>[#{c.archive_name} #{link_to(c.folder_label, procultura_make_link(procultura_folder_path(c.folder_id)))}]</b>"
      else
        spec=''
      end
      r << content_tag(:li, link_to(text, lnk, {:rel=>'lightbox [procultura]', :title=>text})+spec.html_safe)
      prec=c.intestazione
    end
    content_tag(:ol, r.join("\n").html_safe)
  end

  def procultura_cards(folder)
    r=[]
    folder.schede.each do |c|
      ids=c['ids'].gsub(/\{|\}/,'')
      if c['count']=='1'
        lnk=procultura_make_link(procultura_card_path(ids))
        r << content_tag(:li, link_to(c['heading'], lnk, remote:true))
      else
        next if c['heading'].blank?
        lnk=procultura_make_link("/procultura_cards?ids=#{ids.gsub(',','+')}")
        r << content_tag(:li, link_to(c['heading'], lnk, remote:true) + " (#{c['count']} schede)")
      end
    end
    content_tag(:ol, r.join("\n").html_safe)
  end

  def procultura_cards_editable(folder_or_array_of_cards)
    r=[]
    cards = folder_or_array_of_cards.class==ProculturaFolder ? folder_or_array_of_cards.cards : folder_or_array_of_cards
    cards.each do |c|
      r << procultura_cards_table_row(c)
    end
    content_tag(:table, content_tag(:tbody, r.join("\n").html_safe), :class=>'table table-striped')
  end

  def procultura_cards_table_row(record,add_image=false)
    r=[]
    bip=best_in_place(record, :heading, ok_button:'Salva', cancel_button:'Annulla modifiche',
                      ok_button_class:'btn btn-success',
                      class:'btn btn-default',
                      skip_blur:false,
                      html_attrs:{size:record.heading.size}
                      )
    bip2=best_in_place(record, :sort_text, ok_button:'Salva', cancel_button:'Annulla modifiche',
                      ok_button_class:'btn btn-success',
                      class:'btn btn-info',
                      skip_blur:false,
                      html_attrs:{size:record.heading.size}
                      )


    if !record.updated_at.nil? and ((Time.now - record.updated_at).to_i < 180)
      classe='success'
    else
      classe=''
    end

    if add_image
      bip=content_tag(:b, bip)
      r << content_tag(:tr,
                       content_tag(:td, link_to('chiudi', procultura_card_path(record, close:true), remote:true)) +
                       content_tag(:td, bip) +
                       content_tag(:td, "<b>#{bip2}</b>".html_safe) +
                       content_tag(:td, record.updated_by_info),
                       :id=>record.id, class:classe)
      img=image_tag(procultura_card_path(record, :format=>'jpg'))
      r << content_tag(:tr,
                       content_tag(:td, img, {colspan:4}),
                       :id=>"image_#{record.id}")
    else
      r << content_tag(:tr,
                       content_tag(:td, link_to(record.id, procultura_card_path(record), remote:true)) +
                       content_tag(:td, bip) +
                       content_tag(:td, "<b>#{bip2}</b>".html_safe) +
                       content_tag(:td, record.updated_by_info),
                       :id=>record.id, class:classe)
    end
    r.join.html_safe
  end

  def procultura_folders(archive)
    r=[]
    archive.folders.each do |f|
      lnk=procultura_make_link(procultura_folder_path(f))
      r << content_tag(:tr, content_tag(:td, link_to(f.label, lnk)) +
                       content_tag(:td, f.cards.size))
    end
    content_tag(:table, r.join.html_safe)
  end

  def procultura_make_link(base)
    lnk=base
    reqfrom=params[:reqfrom]
    if !reqfrom.blank?
      base.sub!(/^\//,'')
      base.sub!("?", '&')
      lnk="http://#{reqfrom.split('?').first}?resource=#{base}"
    end
    lnk
  end

  def procultura_link_to_image(record,format)
    "http://#{request.host_with_port}#{procultura_card_path(record, {:format=>format})}"
  end

  def procultura_menu_orizzontale(archive_id=nil)
    r=[]
    links=[['Cerca',procultura_folders_path]]
    if !archive_id.blank?
      BioIconograficoCard.lettere.each do |l|
        links << [l,procultura_cards_path(lettera:l,archive_id:archive_id)]
      end
    end
    links.each do |v|
      t,l=v
      lnk=link_to(t,l)
      r << content_tag(:li, lnk)
    end
    content_tag(:ul, r.join.html_safe)
  end

end
