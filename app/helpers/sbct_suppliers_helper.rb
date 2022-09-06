1# coding: utf-8
module SbctSuppliersHelper

  def sbct_suppliers_list(records, maxquota=nil)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Fornitore') +
                            content_tag(:td, 'Copie') +
                            content_tag(:td, 'Sconto') +
                            content_tag(:td, 'Impegnato') +
                            content_tag(:td, 'Media'), class:'success')
    records.each do |r|
      lnk = link_to(r.to_label,sbct_supplier_path(r), target:'_blank')
      impegnato_class = maxquota.nil? ? '' : (r.impegnato.to_f > maxquota ? 'danger' : 'info')
      sconto = (r.discount.blank? or r.discount.to_i==0) ? 'N/D' : "#{r.discount}%"
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.numero_copie) +
                              content_tag(:td, sconto) +
                              content_tag(:td, number_to_currency(r.impegnato), class:impegnato_class) +
                              content_tag(:td, number_to_currency(r.costo_medio)))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_suppliers_per_budget(sbct_budget)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Fornitore', class:'col-md-6') +
                            content_tag(:td, 'Numero copie', class:'col-md-2') +
                            content_tag(:td, 'Stato ordine', class:'col-md-2') +
                            content_tag(:td, 'Importo', class:'col-md-1'), class:'success')
    sbct_budget.suppliers.each do |r|
      lnk = link_to(r.to_label,sbct_items_path("sbct_item[supplier_id]":r.supplier_id,
                                               "sbct_item[budget_id]":sbct_budget.id), target:'_blank')
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, r.order_status) +
                              content_tag(:td, r.importo))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_libraries_per_supplier(sbct_supplier)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-6') +
                            content_tag(:td, 'Numero copie', class:'col-md-2') +
                            content_tag(:td, 'Stato ordine', class:'col-md-2') +
                            content_tag(:td, 'Importo', class:'col-md-1'), class:'success')
    sbct_supplier.libraries.each do |r|
      lnk = link_to(r.library_name,sbct_items_path("sbct_item[library_id]":r.library_id,
                                                   "sbct_item[supplier_id]":sbct_supplier.id), target:'_blank')

      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, r.order_status) +
                              content_tag(:td, r.importo))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end
end
