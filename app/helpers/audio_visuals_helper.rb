module AudioVisualsHelper
  def audio_visuals_index(records)
    res=[]
    records.each do |r|
      colloc=r.collocazione.blank? ? 'non collocato' : r.collocazione.gsub(' ','')
      res << content_tag(:tr, content_tag(:td, colloc) +
                         content_tag(:td, link_to(r.titolo, audio_visual_path(r))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def audio_visual_show(record,show_clavis_manifestations=true)
    res=[]
    skip=[:idvolume,:r_colloc,:prot_fattura,:importo_fattura,:data_sollecito,:data_sospensione,:data_ordine,:data_arrivo,:fornitore,:ordinato,:numero_fattura]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      next if skip.include?(k.to_sym)
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, record[k]))
    end

    if show_clavis_manifestations
      record.clavis_manifestations.each do |cm|
        res << content_tag(:tr, content_tag(:td, cm.id) +
                           content_tag(:td, link_to(cm.title,clavis_manifestation_path(cm.id))))
      end
    else
      res << content_tag(:tr, content_tag(:td, '') +
                         content_tag(:td, link_to("Vai al record #{record.id}",audio_visual_path(record))))
    end
    res=content_tag(:table, res.join.html_safe)
    content_tag(:div, content_tag(:span,"Record #{record.id} da archivio audiovisivi Biblioteca Musicale") + res)
  end

end
