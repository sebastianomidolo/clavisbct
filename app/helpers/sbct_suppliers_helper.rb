1# coding: utf-8
module SbctSuppliersHelper

  def sbct_supplier_report(sbct_suppliers)
    if sbct_suppliers.class == SbctSupplier
      sql = %Q{select cp.order_status,s.label,count(*) from sbct_acquisti.copie cp join sbct_acquisti.budgets b
        using(budget_id) left join sbct_acquisti.order_status s on(s.id=cp.order_status)
          where cp.supplier_id = #{sbct_suppliers.id} group by cp.order_status,s.label
          order by s.label}
    else
      ids = @sbct_suppliers.collect{|s| s.supplier_id}
      ids = ids.join(',')
      sql = %Q{select cp.order_status,s.label,count(*) from sbct_acquisti.copie cp join sbct_acquisti.budgets b
        using(budget_id) left join sbct_acquisti.order_status s on(s.id=cp.order_status)
          where cp.supplier_id IN (#{ids}) group by cp.order_status,s.label
          order by s.label}
    end
    res = []
    SbctSupplier.connection.execute(sql).to_a.each do |r|
      res << content_tag(:tr, content_tag(:td, "#{r['order_status']} - #{r['label']}", class:'col-md-4') +
                              content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')    
  end

  def sbct_suppliers_list_old(records, maxquota=nil, display_total=false)
    res = []
    if maxquota.nil?
      res << content_tag(:tr, content_tag(:td, 'Fornitore') +
                              content_tag(:td, 'Etichetta') +
                              content_tag(:td, 'Copie') +
                              content_tag(:td, 'Sconto') +
                              content_tag(:td, 'Impegnato') +
                              content_tag(:td, 'Media'), class:'success')
    else
      copie_cnt = 0
      impegnato = 0.0
      totale_residuo = 0.0
      res << content_tag(:tr, content_tag(:td, 'Fornitore') +
                              content_tag(:td, 'Copie') +
                              content_tag(:td, 'Sconto') +
                              content_tag(:td, 'Impegnato') +
                              content_tag(:td, 'Residuo') +
                              content_tag(:td, 'Media'), class:'success')
    end
    records.each do |r|
      lnk = link_to("#{r.to_label} (#{r.supplier_id})",sbct_supplier_path(r), target:'_blank')
      impegnato_class = maxquota.nil? ? '' : (r.impegnato.to_f > maxquota ? 'danger' : 'info')
      sconto = (r.discount.blank? or r.discount.to_i==0) ? 'N/D' : "#{r.discount}%"
      ftext = lnk
      ftext = "#{lnk} <b>[#{r.tipologie}]</b>" if !r.tipologie.blank?
      if maxquota.nil?
        res << content_tag(:tr, content_tag(:td, ftext.html_safe) +
                                content_tag(:td, r.shortlabel) +
                                content_tag(:td, r.numero_copie) +
                                content_tag(:td, sconto) +
                                content_tag(:td, number_to_currency(r.impegnato), class:impegnato_class) +
                                content_tag(:td, number_to_currency(r.costo_medio)))
      else
        residuo = maxquota - r.impegnato.to_f
        copie_cnt += r.numero_copie.to_i
        impegnato += r.impegnato.to_f
        totale_residuo += residuo
        res << content_tag(:tr, content_tag(:td, lnk) +
                                content_tag(:td, r.numero_copie) +
                                content_tag(:td, sconto) +
                                content_tag(:td, number_to_currency(r.impegnato), class:impegnato_class) +
                                content_tag(:td, number_to_currency(residuo), class:impegnato_class) +
                                content_tag(:td, number_to_currency(r.costo_medio)))
      end
    end
    if !maxquota.nil? and display_total==true
      res << content_tag(:tr, content_tag(:td, '') +
                              content_tag(:td, copie_cnt) +
                              content_tag(:td, '') +
                              content_tag(:td, number_to_currency(impegnato)) +
                              content_tag(:td, number_to_currency(totale_residuo)) +
                              content_tag(:td, ''), class:'success')
    end

    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end


  def sbct_suppliers_list(records)
    res = []
    copie_cnt = 0
    impegnato = 0.0
    totale_residuo = 0.0
    res << content_tag(:tr, content_tag(:td, 'Fornitore') +
                            content_tag(:td, 'Copie') +
                            content_tag(:td, 'Impegnato') +
                            content_tag(:td, 'Residuo'), class:'success')
    records.each do |r|
      lnk = link_to("#{r.to_label} (#{r.supplier_id})",sbct_supplier_path(r), target:'_blank')
      maxquota = r.quota_fornitore.nil? ? nil : r.quota_fornitore.to_f
      impegnato_class = maxquota.nil? ? '' : (r.impegnato.to_f > maxquota ? 'danger' : 'info')
      ftext = lnk
      ftext = "#{lnk} <b>[#{r.tipologie}]</b>" if !r.tipologie.blank?
      if maxquota.nil?
        res << content_tag(:tr, content_tag(:td, ftext.html_safe) +
                                content_tag(:td, r.shortlabel) +
                                content_tag(:td, r.numero_copie) +
                                content_tag(:td, number_to_currency(r.impegnato), class:impegnato_class))
      else
        residuo = maxquota - r.impegnato.to_f
        copie_cnt += r.numero_copie.to_i
        impegnato += r.impegnato.to_f
        totale_residuo += residuo
        res << content_tag(:tr, content_tag(:td, lnk) +
                                content_tag(:td, r.numero_copie) +
                                content_tag(:td, number_to_currency(r.impegnato), class:impegnato_class) +
                                content_tag(:td, number_to_currency(residuo), class:impegnato_class))
      end
    end
    res << content_tag(:tr, content_tag(:td, '') +
                            content_tag(:td, copie_cnt) +
                            content_tag(:td, number_to_currency(impegnato)) +
                            content_tag(:td, number_to_currency(totale_residuo)), class:'success')
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end


  
  def sbct_suppliers_reassign_list(records, sbct_item)
    res = []
    if records.first.respond_to?('costo_medio')
      res << content_tag(:tr, content_tag(:td, 'Fornitore') +
                              content_tag(:td, "Copie fornite alla biblioteca #{ClavisLibrary.new(library_id:sbct_item.library_id).siglabct}") +
                              content_tag(:td, 'Residuo'), class:'success')
      # costo_medio sta per "residuo"
      tolleranza = params[:tolleranza].blank? ? 0.20 : params[:tolleranza].to_f
      records.each do |r|
        if sbct_item.supplier_id != r.supplier_id and (r.costo_medio + tolleranza) >= sbct_item.prezzo
          lnk = link_to(r.to_label,assign_to_other_supplier_sbct_item_path(sbct_item, target_supplier:r.id), class:'btn btn-warning')
        else
          lnk = r.to_label
        end
        res << content_tag(:tr, content_tag(:td, lnk) +
                                content_tag(:td, r.numero_copie.nil? ? 0 : r.numero_copie) +
                                content_tag(:td, number_to_currency(r.costo_medio)))
      end
    else
      res << content_tag(:tr, content_tag(:td, 'Fornitore') +
                              content_tag(:td, 'Residuo'), class:'success')
      records.each do |r|
        lnk = link_to(r.to_label,assign_to_other_supplier_sbct_item_path(sbct_item, target_supplier:r.id), class:'btn btn-warning')
        res << content_tag(:tr, content_tag(:td, lnk))
      end

    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end
  
  def sbct_suppliers_per_budget(sbct_budget)
    return if sbct_budget.nil?
    res = []
    res << content_tag(:tr, content_tag(:td, 'Fornitore', class:'col-md-6') +
                            content_tag(:td, 'Numero copie', class:'col-md-2') +
                            content_tag(:td, 'Stato ordine', class:'col-md-2') +
                            content_tag(:td, 'Importo', class:'col-md-1'), class:'success')

    s_cnt = numcopie = 0
    totale = 0.0
    sbct_budget.suppliers.each do |r|
      s_cnt += 1
      numcopie += r.numcopie.to_i
      totale += r.importo.to_f
      lnk = link_to(r.to_label,sbct_items_path("sbct_item[supplier_id]":r.supplier_id,
                                               "sbct_item[budget_id]":sbct_budget.id), target:'_blank')
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, r.order_status) +
                              content_tag(:td, r.importo))
    end
    res << content_tag(:tr, content_tag(:td, "#{s_cnt} fornitori", class:'col-md-6') +
                            content_tag(:td, numcopie, class:'col-md-2') +
                            content_tag(:td, '', class:'col-md-2') +
                            content_tag(:td, number_to_currency(totale.round(2)), class:'col-md-1'), class:'success')

    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_libraries_per_supplier(sbct_supplier)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-2') +
                            content_tag(:td, 'Numero copie', class:'col-md-2') +
                            content_tag(:td, 'Stato ordine', class:'col-md-2') +
                            content_tag(:td, 'Importo', class:'col-md-2', align:'center') +
                            content_tag(:td, '', class:'col-md-4'), class:'success')
    numcopie=0
    totale = 0.0
    sbct_supplier.libraries.each do |r|
      next if r.order_status=='N'
      numcopie+=r.numcopie.to_i
      totale += r.importo.to_f
      lnk = link_to(r.library_name,sbct_items_path("sbct_item[library_id]":r.library_id,
                                                   "sbct_item[supplier_id]":sbct_supplier.id,
                                                   "sbct_item[order_status]":r.order_status), target:'_blank')

      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.numcopie,{align:'center'}) +
                              content_tag(:td, r.order_status_label) +
                              content_tag(:td, number_to_currency(r.importo),{align:'right'}) +
                              content_tag(:td, ''))
    end
    totale = totale.round(2)
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-2') +
                            content_tag(:td, numcopie, {align:'center'},class:'col-md-2') +
                            content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, number_to_currency(totale),{align:'right'}, class:'col-md-2') +
                            content_tag(:td, '', class:'col-md-5'), class:'success')

    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

end
