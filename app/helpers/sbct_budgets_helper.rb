# coding: utf-8
module SbctBudgetsHelper

  def sbct_budget_report(budget, library_id=nil)
    return sbct_budget_report_library(budget,library_id) if !library_id.nil?
    res = []
    res << content_tag(:tr, content_tag(:td, 'Stato', class:'col-md-2') +
                            content_tag(:td, 'Copie', class:'col-md-2') +
                            content_tag(:td, 'Importo', class:'col-md-8'), class:'success')
    numcopie = 0
    totale = 0.0
    budget.budget_report.each do |r|
      numcopie += r.numcopie.to_i
      totale += r.totale.to_f
      res << content_tag(:tr, content_tag(:td, link_to(r.stato, sbct_items_path("sbct_item[budget_id]":budget.id,
                                                                                "sbct_item[order_status]":r.order_status), target:'_blank')) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, number_to_currency(r.totale)))
    end
    res << content_tag(:tr, content_tag(:td, "TOTALE") +
                            content_tag(:td, numcopie) +
                            content_tag(:td, number_to_currency(totale)))
    residuo = budget.importo_residuo
    if !residuo.nil?
      testo = residuo < 0 ? "Vanno ancora selezionati libri per <b>#{number_to_currency(residuo)}</b>".html_safe : "Ancora da spendere <b>#{number_to_currency(residuo)}</b> (non sono conteggiate le copie in stato \"Selezionato\")".html_safe
      res << content_tag(:tr, content_tag(:td, testo, {colspan:3}))
    end
    
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_budget_report_library(budget, library_id)
    library=ClavisLibrary.find(library_id)
    res = []
    txt = "Copie #{library.siglabct}"
    res << content_tag(:tr, content_tag(:td, "Per la biblioteca #{library.siglabct} #{library.to_label}", {colspan:3}))
    res << content_tag(:tr, content_tag(:td, 'Stato', class:'col-md-3') +
                            content_tag(:td, txt, class:'col-md-2') +
                            content_tag(:td, 'Importo', class:'col-md-7'), class:'success')

    numcopie = 0
    totale = importo_biblioteca = quota_biblioteca = 0.0
    budget.budget_report(library_id).each do |r|
      importo_biblioteca = r.partial_amount
      quota_biblioteca = r.subquota_amount

      numcopie += r.numcopie.to_i
      totale += r.totale.to_f
      il_totale = number_to_currency(r.totale)
      if r.qb=='f'
        stato = "#{r.stato} (ufficio acquisti)"
      else
        stato = "#{r.stato} (biblioteca)"
        if r.stato=='S'
          if r.totale.to_f > r.subquota_amount.to_f
            il_totale = "#{number_to_currency(r.totale)} (superata la quota di #{number_to_currency(r.subquota_amount)} selezionabile dalla biblioteca)"
          else
            v1 = r.subquota_amount.to_f - r.totale.to_f
            il_totale = "#{number_to_currency(r.totale)} (#{number_to_currency(v1)} ancora disponibili per la biblioteca)"
          end
        end
      end

      
      res << content_tag(:tr, content_tag(:td, link_to(stato, sbct_titles_path(order_status:r.order_status, "sbct_title[titolo]":"budget:#{budget.to_label.strip}","sbct_title[clavis_library_ids]":library_id,qb_select:r.qb=='f' ? 'N' : 'S'), target:'_blank')) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, il_totale))
    end
    res << content_tag(:tr, content_tag(:td, "TOTALE") +
                            content_tag(:td, numcopie) +
                            content_tag(:td, number_to_currency(totale)))

    if numcopie>0
      testo = "Importo totale budget per la biblioteca <b>#{library.siglabct}</b>: #{number_to_currency(importo_biblioteca)}".html_safe
      res << content_tag(:tr, content_tag(:td, testo, {colspan:3}))
      residuo = importo_biblioteca.to_f - totale
      if residuo < 0
        testo = "Attenzione! Residuo: <b>#{number_to_currency(residuo)}</b>".html_safe
      else
        testo = "Residuo: <b>#{number_to_currency(residuo)}</b>".html_safe
      end
      res << content_tag(:tr, content_tag(:td, testo, {colspan:3}))
      testo = "Quota selezionabile dalla biblioteca <b>#{library.siglabct}</b>: #{number_to_currency(quota_biblioteca)}".html_safe
      res << content_tag(:tr, content_tag(:td, testo, {colspan:3}))
    end

    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  
  def sbct_budget_suppliers_list(budget)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Fornitore', class:'col-md-2') +
                            content_tag(:td, 'Tipologie materiale', class:'col-md-2') +
                            content_tag(:td, 'Budget', class:'col-md-4'), class:'success')
    cnt=0
    budget.suppliers_report.each do |r|
      cnt +=1
      res << content_tag(:tr, content_tag(:td, link_to(r.supplier_name,sbct_supplier_path(r.supplier_id))) +
                              content_tag(:td, r.tipologie) +
                              content_tag(:td, r.supplier_for))
    end
    if cnt == 0
      "A questo budget non sono associati fornitori preferiti"
    else
      content_tag(:table, res.join.html_safe, class:'table table-condensed')
    end
  end

  def sbct_budgets_list(records,params={})
    res = []
    if params[:selected].blank?
      res << content_tag(:tr, content_tag(:td, 'Budget') +
                              content_tag(:td, 'Importo') +
                              content_tag(:td, 'Copie') +
                              content_tag(:td, 'Impegnato') +
                              content_tag(:td, 'Media') +
                              content_tag(:td, 'Residuo'), class:'success')
    else
      if params[:checkbox]==true
        hbud = content_tag(:td, '') + content_tag(:td, 'Budget')
      else
        hbud = content_tag(:td, '')
      end
      res << content_tag(:tr, hbud +
                              content_tag(:td, 'Importo') +
                              content_tag(:td, 'Copie selez.') +
                              content_tag(:td, 'Assegnate') +
                              content_tag(:td, 'Impegnato') +
                              content_tag(:td, 'Residuo'), class:'success')
    end
    importo = 0.0
    numcopie = 0
    impegnato = 0.0
    residuo = 0.0
    records.each do |r|
      r.total_amount=-1 if r.total_amount.nil?

      importo += r.total_amount
      numcopie += r.numero_copie.to_i
      impegnato += r.impegnato.to_f
      residuo += r.importo_residuo.to_f
      lnk = link_to(r.label,sbct_budget_path(r), target:'_blank')
      residuo_class = r.importo_residuo.to_f < 0.0 ? 'danger' : ''
      if params[:selected].blank?
        res << content_tag(:tr, content_tag(:td, lnk) +
                                content_tag(:td, number_to_currency(r.total_amount)) +
                                content_tag(:td, r.numero_copie) +
                                content_tag(:td, number_to_currency(r.impegnato)) +
                                content_tag(:td, number_to_currency(r.costo_medio)) +
                                content_tag(:td, number_to_currency(r.importo_residuo.to_f),class:residuo_class))
      else
        if params[:checkbox]==true
          # checkbox = content_tag(:td, check_box_tag("budget_ids[]", r.budget_id, r.assegnate_a_fornitore.to_i == 0 ? true : false))
          checkbox = content_tag(:td, check_box_tag("budget_ids[]", r.budget_id, true))
        else
          checkbox = ''
        end
        prima_colonna = checkbox.html_safe + content_tag(:td, lnk)

        res << content_tag(:tr, prima_colonna +
                                content_tag(:td, number_to_currency(r.total_amount)) +
                                content_tag(:td, "#{r.numero_copie.to_i}") +
                                content_tag(:td, r.assegnate_a_fornitore) +
                                content_tag(:td, number_to_currency(r.impegnato)) +
                                content_tag(:td, number_to_currency(r.importo_residuo),class:residuo_class))
      end
    end
    # if !params[:label].blank?
    if true
      res << content_tag(:tr, content_tag(:td, 'TOTALI', {align:'right'}) +
                              content_tag(:td, number_to_currency(importo)) +
                              content_tag(:td, numcopie) +
                              content_tag(:td, number_to_currency(impegnato))+
                              content_tag(:td, '') +
                              content_tag(:td, number_to_currency(residuo.round(2))), class:'success')
      res << content_tag(:tr, content_tag(:td, '') +
                              content_tag(:td, "<b>Impegnato + residuo: #{number_to_currency(impegnato+residuo)}</b>".html_safe, {colspan:6}) +
                              content_tag(:td, '') +
                              content_tag(:td, '') +
                              content_tag(:td, '') +
                              content_tag(:td, ''), class:'info')
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_budget_show(record)
    res = []
    if !@sbct_budget.clavis_budget.nil?
      res << content_tag(:p, "Budget valido dal #{@sbct_budget.clavis_budget.start_validity} al #{@sbct_budget.clavis_budget.end_validity}") if !@sbct_budget.clavis_budget.start_validity.blank?
      res << content_tag(:p, "Note: #{@sbct_budget.clavis_budget.budget_notes}") if !@sbct_budget.clavis_budget.budget_notes.blank?
    end
    (
      prm = {budget_id:record.id}
      res << sbct_budgets_list(SbctBudget.tutti(prm,current_user))
    )
    # res << link_to('Vedi i titoli associati a questo budget', sbct_titles_path(budget_id:record.id,selection_mode:'',nocovers:'S'))
    # res << link_to("Copie associate a questo budget", sbct_items_path("sbct_item[budget_id]":record.id), target:'_blank')
    res.join("\n").html_safe
  end

  def sbct_budget_libraries(sbct_budget, user=nil)
    return 'non editabile' if !user.nil? and not can? :edit, sbct_budget
    res =[] 
    res << content_tag(:tr, content_tag(:td, 'Sigla', class:'col-md-1') +
                            content_tag(:td, 'Biblioteca', class:'col-md-2') +
                            content_tag(:td, 'Percentuale assegnata', class:'col-md-1') +
                            content_tag(:td, 'Importo', class:'col-md-1') +
                            content_tag(:td, 'Spendibile dalla biblioteca', class:'col-md-2'), class:'success')

    totale_quota = totale_importo = totale_subq = 0.0
    sbct_budget.pac_libraries.each do |r|
      r.id = [r.budget_id,r.library_id]
      lnk = user.nil? ? r.library_name : link_to(r.library_name, edit_sbct_l_budget_library_path(r))
      subq = r.subquota.to_i > 0 ? " (#{r.subquota}%)" : ''
      totale_quota += r.quota.to_f
      totale_importo += r.partial_amount.to_f
      totale_subq += r.subquota_amount.to_f
      res << content_tag(:tr, content_tag(:td, r.siglabct) +
                              content_tag(:td, lnk) +
                              content_tag(:td, "#{r.quota}%") +
                              content_tag(:td, number_to_currency(r.partial_amount)) +
                              content_tag(:td, "#{number_to_currency(r.subquota_amount)}#{subq}"))
    end
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, '', class:'col-md-2') +
                            content_tag(:td, "#{totale_quota.round(2)}%", class:'col-md-1') +
                            content_tag(:td, "#{number_to_currency(totale_importo)}", class:'col-md-1') +
                            content_tag(:td, "#{number_to_currency(totale_subq)}", class:'col-md-2'), class:'success')

    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end


  def sbct_budget_items(sbct_budget,library_ids=nil)
    res=[]
    totale=0.0
    ncopie=0

    heading = content_tag(:tr, content_tag(:td, 'Sigla', class:'col-md-1') +
                               content_tag(:td, 'Quota', class:'col-md-1') +
                               content_tag(:td, 'Importo', class:'col-md-1') +
                               content_tag(:td, 'SubQuota', class:'col-md-1') +
                               content_tag(:td, 'Assegnati', class:'col-md-1') +
                               content_tag(:td, 'Spesi', class:'col-md-1') +
                               content_tag(:td, 'Percent spesi', class:'col-md-1') +
                               content_tag(:td, 'Numero copie', class:'col-md-1') +
                               content_tag(:td, 'Disponibili', class:'col-md-1'), class:'success')
    res << heading

    add_line=lambda do |l|
      l.numero_copie=0
      l.qb=true
      l.subquota = 100 - l.subquota.to_f
      l.assegnati = l.totale_assegnato.to_f - l.assegnati.to_f
      l.spesi = l.spesi_percent = 0
      l.ancora_disp = l.assegnati
      l  
    end
    
    all = []
    prec_line = {}
    qb_ok = false
    prec_sigla = ''
    sbct_budget.sbct_items.each do |r|
       if prec_line != {} and r.qb==prec_line.qb
        all << add_line.call(prec_line)
      end
      prec_line = r.dup
      prec_sigla = r.siglabct
      all << r.dup
    end
    all << add_line.call(prec_line) if prec_line!={} and prec_line.qb == false

    cnt = 0
    all.each do |r|
      cnt += 1
      ncopie += r.numero_copie.to_i
      totale += r.assegnati.to_f

      qb_select = r.qb.blank? ? 'N' : 'S'

      if r.qb.blank?
        classe = 'success'
        row_title = "Scelti da Ufficio acquisti"
        quota = "#{r.quota}%"
        totale_assegnato = number_to_currency(r.totale_assegnato)
        row_id=r.siglabct
      else
        classe = 'info'
        row_title = "Scelti dalla biblioteca #{r.siglabct}"
        quota = totale_assegnato = '-'
        row_id=nil
      end
      biblioteca = %Q{#{link_to(r.siglabct, sbct_titles_path("sbct_title[clavis_library_ids]":r.library_id,copie:'y',budget_id:sbct_budget.id,order_status:'AO',qb_select:qb_select), class:"btn btn-#{classe}")}}.html_safe

      subquota = r.subquota.blank? ? '' : "#{r.subquota}%"
      row_class = r.ancora_disp.to_f < 0 ? 'danger' : ''

      res << content_tag(:tr, content_tag(:td, biblioteca) +
                              content_tag(:td, quota) +
                              content_tag(:td, totale_assegnato) +
                              content_tag(:td, subquota) +
                              content_tag(:td, number_to_currency(r.assegnati)) +
                              content_tag(:td, number_to_currency(r.spesi)) +
                              content_tag(:td, "#{r.spesi_percent}%".html_safe) +
                              content_tag(:td, r.numero_copie) +
                              content_tag(:td, "<b>#{number_to_currency(r.ancora_disp)}</b>".html_safe), class:row_class, title:row_title, id:row_id)

    end
    res << heading
    return '' if cnt==0
    "#{content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')}".html_safe
  end

  def sbct_budget_qb_importo_disponibile(sbct_budget,library_id)
    return 'nessun budget trovato' if sbct_budget.nil?
    res=[]
    disponibile=0.0
    sbct_budget.snapshot(library_id).each_pair do |k,v|
      disponibile = v
      sigla,qb=k
      next if qb==false
      lnk = link_to(sbct_budget.to_label, sbct_budget_path(sbct_budget) + "?##{sigla}", class:'btn btn-info')
      label = "<b>#{sigla}</b> - Importo disponibile su budget #{lnk}"
      res << content_tag(:tr, content_tag(:td, label.html_safe, class:'col-md-7') +
                              content_tag(:td, "#{number_to_currency(v)}"))
    end
    sql = %Q{select sum(prezzo*numcopie) as prezzo,count(*) from sbct_acquisti.copie
              WHERE qb and order_status='S' and library_id=#{library_id} and budget_id=#{sbct_budget.id}}
    cr=sbct_budget.connection.execute(sql).first
    
    if cr['count'].to_i > 0
      prezzo = cr['prezzo'].blank? ? 0 : cr['prezzo']
      lnk = link_to("#{cr['count']} copie",sbct_titles_path(budget_id:sbct_budget.id, "sbct_title[clavis_library_ids]":library_id, order_status:'S', qb_select:'S',copie:'y'))
      # lnk = "<b>#{cr['count']} copie</b>"
      res << content_tag(:tr, content_tag(:td, "Selezionate e non ancora ordinate #{lnk}".html_safe, class:'col-md-7') +
                              content_tag(:td, "#{number_to_currency(prezzo)}"))
      residuo = disponibile - prezzo.to_f
      res << content_tag(:tr, content_tag(:td, "Se venissero ordinate tutte resterebbero #{content_tag(:b, number_to_currency(residuo))}".html_safe, class:'col-md-7') +
                              content_tag(:td, ''))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_budgets_browse(record,ids)
    return if  ids.index(record.id).nil?
    p = record.browse_object('prev',ids)
    n = record.browse_object('next',ids)
    curpos = ids.index(record.id) + 1
    ccss = 'btn btn-info'
    ccss = 'label label-info'
    tot=ids.size
    lnks = []
    if !p.nil?
      lnks << link_to(content_tag(:span, '|<', class:ccss, budget:"1 / #{tot}"), sbct_budget_path(record.browse_object('first',ids)))
      lnks << link_to(content_tag(:span, ' < ', class:ccss), sbct_budget_path(p))
    else
      lnks << content_tag(:span, '|<', class:ccss)
      lnks << content_tag(:span, ' < ', class:ccss)
    end
    if !n.nil?
      lnks << link_to(content_tag(:span, ' > ', class:ccss), sbct_budget_path(n))
      lnks << link_to(content_tag(:span, '>|', class:ccss, budget:"#{tot} / #{tot}"), sbct_budget_path(record.browse_object('last',ids)))
    else
      lnks << content_tag(:span, ' > ', class:ccss)
      lnks << content_tag(:span, '>|', class:ccss)
    end
    content_tag(:span, "#{lnks.join('')} [#{curpos}/#{tot}]".html_safe, class:ccss)
  end
  
end
