# coding: utf-8
module SbctEventsHelper

  def sbct_event_types_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'Tipologia evento', class:'col-md-2 text-left'), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.event_type_id, edit_sbct_event_type_path(r), class:'btn btn-success')) +
                              content_tag(:td, r.label))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end


  def sbct_events_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Nome evento', class:'col-md-1') +
                            content_tag(:td, 'Tipologia', class:'col-md-1 text-left') +
                            content_tag(:td, 'Stato', class:'col-md-1') +
                            content_tag(:td, '', class:'col-md-2 text-left'), class:'success')
    records.each do |r|
      if r.sbct_titles.size==0
        lnk = link_to("Elimina", r, method: :delete, data: { confirm: "Confermi eliminazione dell'evento?" }, class:'btn btn-warning')
      else
        lnk = "#{r.sbct_titles.size} titoli"
      end
      res << content_tag(:tr, content_tag(:td, link_to(r.name, sbct_event_path(r), class:'btn btn-success')) +
                              content_tag(:td, r.event_type_id) +
                              content_tag(:td, r.sbct_event_status.to_label) +
                              content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  
end
