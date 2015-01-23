
module OrdiniHelper
  def ordini_index(records)
    return '' if records.size==0
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r.titolo) +
                         content_tag(:td, r.periodo) +
                         content_tag(:td, link_to(r.manifestation_id, ClavisManifestation.clavis_url(r.manifestation_id,:show))))
    end
    res << content_tag(:div, "Trovati #{records.total_entries} esemplari", class: 'panel-heading')
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def ordini_fatture(records)
    return '' if records.size==0
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Numero fattura') +
                       content_tag(:td, 'Data emissione')+
                       content_tag(:td, 'Data pagamento')+
                       content_tag(:td, 'Totale fattura')+
                       content_tag(:td, 'Library id')+
                       content_tag(:td, 'Numero titoli'))

    records.each do |r|
      lid=r['library_id']
      lnk=link_to("#{r['numero_fattura']}", fatture_ordini_path(:library_id=>lid, :numero_fattura=>r['numero_fattura']))
      res << content_tag(:tr, content_tag(:td, lnk) +
                         content_tag(:td, r['data_emissione'])+
                         content_tag(:td, r['data_pagamento'])+
                         content_tag(:td, r['totale_fattura'])+
                         content_tag(:td, lid)+
                         content_tag(:td, r['numero_titoli']))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def ordini_fatture_riepilogo(records)
    return '' if records.size==0
    res=[]
    totale_impegnato=0
    totale_pagato=0
    da_pagare=0
    records.each do |r|
      totale_impegnato += r['totale_fattura'].to_f
      totale_pagato += r['totale_fattura'].to_f if !r['data_pagamento'].blank?
      da_pagare += r['totale_fattura'].to_f if r['data_pagamento'].blank?
    end
    res << content_tag(:tr, content_tag(:td, 'Totale fatturato') + content_tag(:td, totale_impegnato.round(2)))
    res << content_tag(:tr, content_tag(:td, 'Totale pagato') + content_tag(:td, totale_pagato.round(2)))
    res << content_tag(:tr, content_tag(:td, 'Da pagare') + content_tag(:td, da_pagare.round(2)))

    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def ordini_dettaglio_ordine(r)
    res=[]
    if !r['numero_fattura'].blank?
      tipodoc=r['tipodoc']=='F' ? 'Fattura' : 'Nota di credito'
      res << content_tag(:tr,
                         content_tag(:td, tipodoc + ' numero') +
                         content_tag(:td,content_tag(:b, r['numero_fattura'])))
    end
    ['cig','stato','data_emissione','periodo','formato','prezzo','sconto','prezzo_finale','note_interne'].each do |f|
      next if r[f].blank?
      res << content_tag(:tr, content_tag(:td,f.capitalize) + content_tag(:td, r[f]))
    end
    # res << (r['iva'] == '0' ? '' : content_tag(:tr, content_tag(:td,'IVA') + content_tag(:td,r['iva'])))
    content_tag(:table, res.join.html_safe)
  end
end
