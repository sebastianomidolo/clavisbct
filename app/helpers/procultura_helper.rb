# -*- coding: utf-8 -*-
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
      r << content_tag(:li, link_to(e['name'], lnk) + " (#{e['count']} schede)")
    end
    content_tag(:h3, 'Attenzione: questa pagina non è ancora stata pubblicata ufficialmente sul sito delle Biblioteche Civiche Torinesi') + content_tag(:ul, r.join.html_safe)
  end

  def procultura_cards_singole_schede(folder)
    r=[]
    cnt=0
    prec=nil
    folder.cards.each do |c|
      cnt=0 if prec!=c.intestazione
      cnt+=1
      lnk=procultura_make_link(procultura_card_path(c))
      if cnt==1
        text=c.intestazione
      else
        text="#{c.intestazione} (#{cnt})"
      end
      r << content_tag(:tr, content_tag(:td, link_to(text, lnk)))
      prec=c.intestazione
    end
    content_tag(:table, r.join.html_safe)
  end

  def procultura_cards(folder)
    r=[]
    folder.schede.each do |c|
      ids=c['ids'].gsub(/\{|\}/,'')
      if c['count']=='1'
        lnk=procultura_make_link(procultura_card_path(ids))
        r << content_tag(:li, link_to(c['heading'], lnk))
      else
        next if c['heading'].blank?
        lnk=procultura_make_link("/procultura_cards?ids=#{ids.gsub(',','+')}")
        r << content_tag(:li, link_to(c['heading'], lnk) + " (#{c['count']} schede)")
      end
    end
    content_tag(:ol, r.join("\n").html_safe)
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
end
