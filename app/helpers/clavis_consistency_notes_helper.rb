module ClavisConsistencyNotesHelper

  def clavis_consistency_notes_index(records)
    res=[]
    records.each do |r|
      title=r.title.blank? ? '[?]' : r.title[0..80]
      casse = r.casse.size==0 ? '' : r.casse.collect {|z| z['cassa'] }.join(', ')
      # casse << "<br/> eventuale url"
      casse = params[:fmt]=='short' ? '' : content_tag(:td, casse.html_safe, class:'col-md-4')
      # content_tag(:td, content_tag(:b, "Per.#{r.collocazione_per}"), :class=>'info')
      if r.URL.blank?
        bid = r.bid
      else
        er_link=link_to('Vedi qui', "/er?clavis_manifestation[bid]=#{r.bid}", target:'_new')
        bid = "#{r.bid}<br/><b>#{link_to('URL', r.URL.gsub('&amp;','&'))}</b><br/>#{er_link}".html_safe
      end

      # bid = r.URL.blank? ? r.bid : "#{r.bid}<br/><b>#{link_to('URL', r.URL)}</b>".html_safe
      res << content_tag(:tr, 
                         content_tag(:td, link_to(r.collocation, clavis_consistency_note_path(r.id),
                                                  :target=>'_blank'),class:'col-md-1') +
                         content_tag(:td, bid, class:'col-md-1') +
                         content_tag(:td, r.text_note, class:'col-md-1') + casse +
                         content_tag(:td,
                                     link_to(title, ClavisManifestation.clavis_url(r.manifestation_id,:show), :target=>'_blank') + link_to('<br/><b>[opac]</b>'.html_safe, ClavisManifestation.clavis_url(r.manifestation_id,:opac), :target=>'_blank'),
                                     class:'col-md-6'))


    end
    # content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'), :class=>'table-responsive')
    content_tag(:table, res.join("\n").html_safe, :class=>'table table-bordered table-striped table-condensed')
  end

  def clavis_consistency_notes_list_by_manifestation_id(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td,content_tag(:div, clavis_consistency_note_show(r))))
    end
    content_tag(:table, res.join("\n").html_safe, :class=>'table table-bordered table-striped table-condensed')
  end

  def clavis_consistency_notes_periodici_in_casse(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Consistenza', class:'col-md-1') +
                            content_tag(:td, 'Annata', class:'col-md-2') +
                            content_tag(:td, 'Cassa', class:'col-md-1') +
                            content_tag(:td, 'Note'))
    output=false
    records.each do |r|
      output=true
      res << content_tag(:tr, content_tag(:td, r['consistenza'], class:'col-md-1') +
                              content_tag(:td, r['annata'], class:'col-md-2') +
                              content_tag(:td, r['cassa'], class:'col-md-1') +
                              content_tag(:td, r['note']))
    end
    return '' if !output
    content_tag(:div, "<p><b>Civica Centrale: materiale in deposito esterno disponibile su prenotazione</b></p>".html_safe + content_tag(:table, res.join('').html_safe, :class=>'table table-bordered table-striped table-condensed'))
  end

  def clavis_consistency_note_casse(record)
    res=[]
    cnt=0
    res << content_tag(:tr, content_tag(:td, 'Consistenza') +
                       content_tag(:td, 'Annata') +
                       content_tag(:td, 'Posizione') +
                       content_tag(:td, 'Note'))
    record.casse.each do |r|
      cnt+=1
      res << content_tag(:tr, content_tag(:td, r['consistenza']) +
                         content_tag(:td, r['annata']) +
                         content_tag(:td, content_tag(:b, r['cassa']) +
                         content_tag(:td, r['note'])))
    end
    cnt==0? '' : content_tag(:table, res.join.html_safe, :class=>'table table-striped')
  end

  def clavis_consistency_note_show(record)
    if record.collocazione_per==999
      ClavisConsistencyNote.create_periodici_in_casse
    end
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Consistenza in Clavis',class:'col-md-2') + content_tag(:td, record.text_note))
    res << content_tag(:tr, content_tag(:td, 'Collocazione numerica (per.)') + content_tag(:td, record.collocazione_per)) if !record.collocazione_per.blank?
    cn=content_tag(:table, res.join.html_safe, :class=>'table')

    out = []
    cm=record.clavis_manifestation
    bib=ClavisLibrary.find(record.library_id)
    out << content_tag(:div, content_tag(:div, content_tag(:h3, "<b>Nota di consistenza</b> (#{bib.label}) #{link_to(cm.title, clavis_manifestation_path(cm.id), :target=>'_blank')}<br/><b>#{record.collocation}</b>".html_safe, class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
    out << content_tag(:div, cn+clavis_consistency_note_casse(record), class: 'panel-body')
    out.join.html_safe
  end
end
