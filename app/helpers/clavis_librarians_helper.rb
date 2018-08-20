# coding: utf-8
module ClavisLibrariansHelper

  def clavis_librarians_list(records)
    res = []
    res << content_tag(:tr, content_tag(:th, "Nome operatore", class:'col-md-3') +
                            content_tag(:th, "Inizio sessione") +
                            content_tag(:th, "Biblioteca"))
    records.each do |r|
      res << content_tag(:tr, content_tag(:td,
                                          link_to("#{r['name']} #{r['lastname']}",
                                                  clavis_librarian_path(r['librarian_id']), target:'_blank')) +
                              content_tag(:td, r['start_date']) +
                              content_tag(:td, r['library']))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def clavis_librarian_sessions(record)
    res = []
    res << content_tag(:tr, content_tag(:th, '#', class:'col-md-1') +
                            content_tag(:th, 'Biblioteca', class:'col-md-2') +
                            content_tag(:th, 'start_date', class:'col-md-2') +
                            content_tag(:th, 'end_date'))
    cnt=0
    record.clavis_sessions.each do |r|
      cnt += 1
      res << content_tag(:tr, content_tag(:td, cnt) +
                              content_tag(:td, r['shortlabel'].blank? ? r['label'] : r['shortlabel']) +
                              content_tag(:td, r['start_date']) +
                              content_tag(:td, r['end_date']))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

end

