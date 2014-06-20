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

  def ordini_fatture(ordine,records)
    return '' if records.size==0
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Numero fattura') +
                       content_tag(:td, 'Data emissione')+
                       content_tag(:td, 'Data pagamento')+
                       content_tag(:td, 'Totale fattura')+
                       content_tag(:td, 'Numero titoli'))

    records.each do |r|
      lnk=link_to("#{r['numero_fattura']}", fatture_ordini_path(:library_id=>@library.id, :numero_fattura=>r['numero_fattura']))
      res << content_tag(:tr, content_tag(:td, lnk) +
                         content_tag(:td, r['data_emissione'])+
                         content_tag(:td, r['data_pagamento'])+
                         content_tag(:td, r['totale_fattura'])+
                         content_tag(:td, r['numero_titoli']))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')

  end
end
