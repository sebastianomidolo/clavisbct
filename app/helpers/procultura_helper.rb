# lastmod 7 marzo 2013

module ProculturaHelper

  def procultura_archivi
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

  def procultura_cards(folder)
    r=[]
    cnt=0
    prec=nil
    folder.cards.each do |c|
      cnt=0 if prec!=c.heading
      cnt+=1
      lnk=procultura_make_link(procultura_card_path(c))
      if cnt==1
        text=c.heading
      else
        text="#{c.heading} (#{cnt})"
      end
      r << content_tag(:tr, content_tag(:td, link_to(text, lnk)))
      prec=c.heading
    end
    content_tag(:table, r.join.html_safe)
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

  def procultura_link_to_pdf(record)
    # reqfrom=params[:reqfrom]
    # reqfrom=reqfrom.split('?').first if !reqfrom.blank?
    lnk="http://#{request.host_with_port}#{procultura_card_path(record, {:format=>:pdf})}"
    # lnk="http://#{reqfrom}?resource=#{lnk}" if !reqfrom.blank?
  end
end
