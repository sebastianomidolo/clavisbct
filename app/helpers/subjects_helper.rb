# -*- coding: utf-8 -*-
module SubjectsHelper

  def subject_related_terms(record)
    res=[]


    if !record.suddivisione_di.nil?
      lnk=link_to(record.suddivisione_di.heading, record.suddivisione_di)
      ln=record.suddivisione_di.linknote
      lnk = "#{ln} es. #{lnk}".html_safe if !ln.blank?
      res << content_tag(:div, content_tag(:div, content_tag(:h3, "Suddivisione di #{lnk}".html_safe, class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-warning')
    end

    if record.see.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Vedi', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
      res << content_tag(:div, subject_ref(record, 'see'), class: 'panel-body')
    end

    if record.use_for.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Usato al posto di', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
      res << content_tag(:div, subject_ref(record, 'use_for'), class: 'panel-body')
    end


    if record.seealso.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Vedi anche', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
      res << content_tag(:div, subject_seealso(record), class: 'panel-body')
    end

    if record.bt.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Più in generale vedi', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-success')
      res << content_tag(:div, subject_bt(record), class: 'panel-body')
    end

    if record.suddivisioni.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Suddivisioni', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-success')
      res << content_tag(:div, subject_suddivisioni(record), class: 'panel-body')
    end

    au=record.clavis_authority
    if !au.nil? and !au.clavis_authority.nil?
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Soggetti usati in Clavis', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-alert')
      res << content_tag(:div, subjects_clavis_authority_other_subjects(record), class: 'panel-body')
    end

    if record.clavis_manifestations.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, "Titoli in Clavis (#{record.clavis_manifestations.size})", class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-success')
      cnt=0
      record.clavis_manifestations.each do |cm|
        cnt+=1
        res << content_tag(:div, clavis_manifestation_opac_preview(cm), class: 'panel-body')
        break if cnt>=3
      end
      res << content_tag(:div, clavis_manifestations_shortlist(record.clavis_manifestations), class: 'panel-body')
    end

    res.join.html_safe
  end

  def subject_seealso(record)
    res=[]
    record.seealso.each do |r|
      lnk = (/^anche/ =~ r.heading)==0 ? r.heading : link_to(r.heading, subject_path(r))
      lnk = "#{r.linknote} es. #{lnk}".html_safe if !r.linknote.blank?
      res << content_tag(:p, lnk)
    end
    res.join.html_safe
  end

  def subject_ref(record, method)
    res=[]
    record.send(method).each do |r|
      lnk = link_to(r.heading, subject_path(r))
      res << content_tag(:p, lnk)
    end
    res.join.html_safe
  end

  def subject_bt(record)
    res=[]
    record.bt.each do |r|
      lnk = link_to(r.heading, subject_path(r))
      lnk = "#{r.linknote} es. #{lnk}".html_safe if !r.linknote.blank?
      res << content_tag(:p, lnk)
    end
    res.join.html_safe
  end

  def subject_suddivisioni(record)
    res=[]
    record.suddivisioni.each do |r|
      # res << content_tag(:p, link_to(r.heading, subject_path(r)))
      lnk = link_to(r.heading, subject_path(r))
      lnk = "#{r.linknote} es. #{lnk}".html_safe if !r.linknote.blank?
      res << content_tag(:p, lnk)

    end
    res.join.html_safe
  end


  def subjects_clavis_authority_other_subjects(record)
    res=[]
    record.clavis_authority_other_subjects.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['full_text'], subject_path(r['subject_id']))) +
                         content_tag(:td, r['titoli']) +
                         content_tag(:td, link_to(r['subject_class'], ClavisAuthority.clavis_url(r['authority_id']))))
    end
    content_tag(:table, res.join.html_safe)
  end

end
