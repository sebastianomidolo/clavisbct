# coding: utf-8
module BibSectionsHelper

  def bib_sections_list(records)
    res = []
    records.each do |r|
      lnktit=link_to('Modifica', edit_bib_section_path(r), class:'btn btn-info', title:'Collocazioni ospitate', target:'_new')
      name = r.name.blank? ? '(senza nome)' : r.name
      res << content_tag(:tr, content_tag(:td, link_to(name, bib_section_path(r))) +
                              content_tag(:td, lnktit) +
                              content_tag(:td, link_to('Elimina', r, method: :delete, data: { confirm: 'Cancelli questa sezione?' })))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def bib_sections_list_readonly(records)
    res = []
    records.each do |r|
      name = r.name.blank? ? '(senza nome)' : r.name
      res << content_tag(:tr, content_tag(:td, link_to(name, bib_section_path(r))))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

end
