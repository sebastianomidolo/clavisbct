# coding: utf-8
module SbctListsHelper

  def sbct_lists_index(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Nome della lista', class:'col-md-3') +
                            content_tag(:td, 'Meta-Budget', class:'col-md-3') +
                            content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'Numero titoli', class:'col-md-5'), class:'success')
      records.each do |r|
      if r.data_libri.nil?
        txt = r.label
      else
        txt = r.data_libri.to_s
        txt << " - #{r.label}" if !r.label.blank?
        # lnk = link_to(txt, sbct_titles_path(id_lista:r.id_lista))
      end
      lnk = link_to(txt, sbct_list_path(r.id_lista))
      blink = r.budget_label.blank? ? '-' : link_to(r.budget_label, sbct_budgets_path(budget_label:r.budget_label),target:'_blank')
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, blink) +
                              content_tag(:td, r.tipo_titolo) +
                              content_tag(:td, r.cnt))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sbct_list_index(records, table_title='')
    return '' if records.size==0
    res = []
    res << content_tag(:tr, content_tag(:td, 'File di origine', class:'col-md-2') +
                            content_tag(:td, 'Data di caricamento', class:'col-md-2') +
                            content_tag(:td, 'Numero titoli', class:'col-md-1'), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r.original_filename) +
                              content_tag(:td, r.date_created.to_date) +
                              content_tag(:td, r.count))
    end
    table_title + content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_list_toc(sbct_list, records, table_title='')
    return '' if records.size==0
    res = []
    res << content_tag(:tr, content_tag(:td, 'Reparto', class:'col-md-2') +
                            content_tag(:td, 'Sottoreparto', class:'col-md-2') +
                            content_tag(:td, 'Numero titoli', class:'col-md-1'), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.reparto, sbct_titles_path("sbct_title[reparto]":r.reparto,id_lista:sbct_list.id))) +
                              content_tag(:td, link_to(r.sottoreparto, sbct_titles_path("sbct_title[sottoreparto]":r.sottoreparto,id_lista:sbct_list.id))) +
                              content_tag(:td, r.count))
    end
    table_title + content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

end
  
