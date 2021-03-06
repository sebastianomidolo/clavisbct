# -*- coding: utf-8 -*-
module SubjectsHelper

  def subject_related_terms(record,embedded=false)
    res=[]

    if !record.suddivisione_di.nil?
      lnk=link_to(record.suddivisione_di.heading, subject_path(record.suddivisione_di,:embedded=>embedded))
      ln=record.suddivisione_di.linknote
      lnk = "#{ln} es. #{lnk}".html_safe if !ln.blank?
      res << content_tag(:div, content_tag(:div, content_tag(:h3, "Suddivisione di #{lnk}".html_safe, class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-warning')
    end

    if record.see.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Vedi', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
      res << content_tag(:div, subject_ref(record, 'see', embedded), class: 'panel-body')
    end

    if record.use_for.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Usato al posto di', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
      res << content_tag(:div, subject_ref(record, 'use_for', embedded), class: 'panel-body')
    end


    if record.seealso.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Vedi anche', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
      res << content_tag(:div, subject_seealso(record, embedded), class: 'panel-body')
    end

    if record.bt.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Più in generale vedi', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-success')
      res << content_tag(:div, subject_bt(record, embedded), class: 'panel-body')
    end

    if record.suddivisioni.size>0
      res << content_tag(:div, content_tag(:div, content_tag(:h3, 'Suddivisioni', class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-success')
      res << content_tag(:div, subject_suddivisioni(record, embedded), class: 'panel-body')
    end

    au=record.clavis_authority
    if !au.nil? and !au.clavis_authority.nil? and record.heading.split('- ').size==1
      res << content_tag(:div, content_tag(:div, content_tag(:h3, "La voce <b>#{record.heading}</b> è utilizzata in questi soggetti Clavis".html_safe, class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-alert')
      res << content_tag(:div, subjects_clavis_authority_other_subjects(record, embedded), class: 'panel-body')
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

  def subject_seealso(record, embedded)
    res=[]
    record.seealso.each do |r|
      lnk = (/^anche/ =~ r.heading)==0 ? r.heading : link_to(r.heading, subject_path(r,:embedded=>embedded))
      lnk = "#{r.linknote} es. #{lnk}".html_safe if !r.linknote.blank?
      res << content_tag(:p, lnk)
    end
    res.join.html_safe
  end

  def subject_ref(record, method, embedded)
    res=[]
    record.send(method).each do |r|
      lnk = link_to(r.heading, subject_path(r, :embedded=>embedded))
      res << content_tag(:p, lnk)
    end
    res.join.html_safe
  end

  def subject_bt(record, embedded)
    res=[]
    record.bt.each do |r|
      lnk = link_to(r.heading, subject_path(r, :embedded=>embedded))
      lnk = "#{r.linknote} es. #{lnk}".html_safe if !r.linknote.blank?
      res << content_tag(:p, lnk)
    end
    res.join.html_safe
  end

  def subject_suddivisioni(record, embedded)
    res=[]
    record.suddivisioni.each do |r|
      # res << content_tag(:p, link_to(r.heading, subject_path(r)))
      lnk = link_to(r.heading, subject_path(r, :embedded=>embedded))
      lnk = "#{r.linknote} es. #{lnk}".html_safe if !r.linknote.blank?
      res << content_tag(:p, lnk)

    end
    res.join.html_safe
  end


  def subjects_clavis_authority_other_subjects(record, embedded)
    res=[]
    record.clavis_authority_other_subjects.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['full_text'], subject_path(r['subject_id'], :embedded=>embedded))) +
                         content_tag(:td, r['titoli']) +
                         content_tag(:td, link_to(r['subject_class'], ClavisAuthority.clavis_url(r['authority_id']), :target=>'_blank')))
    end
    content_tag(:table, res.join.html_safe)
  end

  def subjects_duplicate_terms(records)
    res=[]
    cnt=0
    records.each do |r|
      i=0
      classi=[]
      ids=r['authority_ids'].gsub(/{|}/,'').split(',')
      r['subject_classes'].gsub(/{|}/,'').split(',').each do |c|
        # classi << "#{i}: #{c} => #{ids[i]}"
        classi << link_to("#{c} => #{ids[i]}", ClavisAuthority.clavis_url(ids[i],:edit)) + " #{ids[i]}"
        i+=1
      end
      cnt+=1
      res << content_tag(:tr, content_tag(:td, cnt) +
                              content_tag(:td, r['heading']) +
                              content_tag(:td, classi.join(', ').html_safe))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end
end
