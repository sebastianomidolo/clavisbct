# coding: utf-8
module SbctBudgetsHelper

  def sbct_budget_report(budget)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Stato', class:'col-md-2 text-center') +
                            content_tag(:td, 'Copie', class:'col-md-1 text-center') +
                            content_tag(:td, 'Importo', class:'col-md-4 text-center') +
                            content_tag(:td, '', class:'col-md-7'), class:'success')
    numcopie = 0
    totale = 0.0
    residuo = nil
    budget.budget_report.each do |r|
      numcopie += r.numcopie.to_i
      totale += r.totale.to_f
      residuo = (r.totale.to_f - budget.total_amount.to_f) if r.order_status=='O'
      res << content_tag(:tr, content_tag(:td, link_to(r.stato, sbct_items_path("sbct_item[budget_id]":budget.id,
                                                                                "sbct_item[order_status]":r.order_status), target:'_blank')) +
                              content_tag(:td, r.numcopie, class:'text-right') +
                              content_tag(:td, number_to_currency(r.totale), class:'text-right'))
    end
    res << content_tag(:tr, content_tag(:td, "TOTALE") +
                            content_tag(:td, numcopie, class:'text-right') +
                            content_tag(:td, number_to_currency(totale), class:'text-right'))
    residuo = nil if residuo==0
    if !residuo.nil?
      testo = residuo < 0 ? "Vanno ancora selezionati libri per <b>#{number_to_currency(residuo)}</b>".html_safe : "Ancora da spendere <b>#{number_to_currency(residuo)}</b>".html_safe
      res << content_tag(:tr, content_tag(:td, '') +
                              content_tag(:td, '') +
                              content_tag(:td, testo, class:'text-right'))
    end
    
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_budgets_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Budget') +
                            content_tag(:td, 'Importo') +
                            content_tag(:td, 'Copie') +
                            content_tag(:td, 'Impegnato') +
                            content_tag(:td, 'Media') +
                            content_tag(:td, 'Residuo'), class:'success')
    records.each do |r|
      lnk = link_to(r.label,sbct_budget_path(r), target:'_blank')
      residuo_class = r.residuo.to_f < 0 ? 'danger' : ''
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, number_to_currency(r.total_amount)) +
                              content_tag(:td, r.numero_copie) +
                              content_tag(:td, number_to_currency(r.impegnato)) +
                              content_tag(:td, number_to_currency(r.costo_medio)) +
                              content_tag(:td, number_to_currency(r.residuo),class:residuo_class))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_budget_show(record)
    res = []
    res << content_tag(:p, "Budget valido dal #{@sbct_budget.clavis_budget.start_validity} al #{@sbct_budget.clavis_budget.end_validity}") if !@sbct_budget.clavis_budget.start_validity.blank?
    res << content_tag(:p, "Note: #{@sbct_budget.clavis_budget.budget_notes}") if !@sbct_budget.clavis_budget.budget_notes.blank?
    res << sbct_budgets_list(SbctBudget.tutti(budget_id:record.id))
    # res << link_to('Vedi i titoli associati a questo budget', sbct_titles_path(budget_id:record.id,selection_mode:'',nocovers:'S'))
    res << link_to("Copie associate a questo budget", sbct_items_path("sbct_item[budget_id]":record.id), target:'_blank')

    
    res.join("\n").html_safe
  end

  def sbct_liste_per_budget(record)
    res = []
    res << content_tag(:tr, content_tag(:td, '"Data libri"', class:'col-md-2') +
                            content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'Tipo lista', class:'col-md-2') +
                            content_tag(:td, 'Numero copie', class:'col-md-1'), class:'success')

    record.liste.each do |r|
      # lnk = link_to(r.data_libri,sbct_titles_path(id_lista:r.id_lista,in_clavis:'',budget_id:record.id), target:'_blank')
      lnk = link_to(r.data_libri,sbct_titles_path(id_lista:r.id_lista,budget_id:record.id), target:'_blank')
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.label) +
                              content_tag(:td, r.tipo_titolo) +
                              content_tag(:td, r.numero_copie))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

end
