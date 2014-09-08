module ClavisConsistencyNotesHelper

  def clavis_consistency_notes_index(records)
    res=[]
    records.each do |r|
      title=r.title.blank? ? '[?]' : r.title
      casse = r.casse.size==0 ? '' : r.casse.collect {|z| z.cassa }.join(', ')
      casse = params[:fmt]=='short' ? '' : content_tag(:td, casse)
      res << content_tag(:tr, content_tag(:td, content_tag(:b, "Per.#{r.collocazione_per}"), :class=>'info') +
                         content_tag(:td, link_to(r.collocation, clavis_consistency_note_path(r.id),
                                                  :target=>'_blank')) +
                         content_tag(:td, r.text_note) + casse +
                         content_tag(:td, link_to(title, ClavisManifestation.clavis_url(r.manifestation_id,:show),
                                                  :target=>'_blank')))
    end
    # content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'), :class=>'table-responsive')
    content_tag(:table, res.join("\n").html_safe, :class=>'table table-bordered table-striped table-condensed')
  end


  def clavis_consistency_note_show(record)
    if record.collocazione_per==999
      ClavisConsistencyNote.create_periodici_in_casse
    end
    res=[]
    cnt=0
    res << content_tag(:tr, content_tag(:td, 'Consistenza') +
                       content_tag(:td, 'Annata') +
                       content_tag(:td, 'Note') +
                       content_tag(:td, 'Cassa'))
    record.casse.each do |r|
      cnt+=1
      res << content_tag(:tr, content_tag(:td, r.consistenza) +
                         content_tag(:td, r.annata) +
                         content_tag(:td, r.note) +
                         content_tag(:td, content_tag(:b, r.cassa)))
    end
    casse = cnt==0? '' : content_tag(:table, res.join.html_safe, :class=>'table table-striped')

    res=[]
    # res << content_tag(:tr, content_tag(:td, 'Collocazione') + content_tag(:td, record.collocation))
    res << content_tag(:tr, content_tag(:td, 'Consistenza in Clavis') + content_tag(:td, record.text_note))
    res << content_tag(:tr, content_tag(:td, 'Collocazione numerica (per.)') + content_tag(:td, record.collocazione_per))
    cn=content_tag(:table, res.join.html_safe, :class=>'table')

    out = []
    cm=record.clavis_manifestation
    out << content_tag(:div, content_tag(:div, content_tag(:h3, "<b>Nota di consistenza</b> #{link_to(cm.title, cm.clavis_url, :target=>'_blank')}<br/><b>#{record.collocation}</b>".html_safe, class: 'panel-title'), class: 'panel-heading'), class: 'panel panel-info')
    out << content_tag(:div, cn+casse, class: 'panel-body')
    out.join.html_safe
  end
end
