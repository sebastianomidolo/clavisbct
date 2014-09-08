module AudioVisualsHelper
  def audio_visuals_index(records)
    res=[]
    records.each do |r|
      colloc=r.collocazione.blank? ? 'non collocato' : r.collocazione.gsub(' ','')
      res << content_tag(:tr, content_tag(:td, colloc) +
                         content_tag(:td, link_to(r.titolo, audio_visual_path(r))) +
                         content_tag(:td, r.autore) +
                         content_tag(:td, r.interpreti))

    end
    content_tag(:table, res.join.html_safe)
  end

  def audio_visual_show(record,show_clavis_manifestations=true)
    res=[]
    fields=[:autore,:titolo,:collocazione,:interpreti,:editore,:numero_editoriale,:anno_edizione]
    # fields=record.attributes.keys
    fields.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, record[k]))
    end
    if !record.naxos_link.blank?
      res << content_tag(:tr, content_tag(:td, '') + content_tag(:td, link_to(record.naxos_link, record.naxos_link, {target: '_new'})))
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
    # content_tag(:div, content_tag(:span,"Record #{record.id} da archivio audiovisivi Biblioteca Musicale") + res)
    content_tag(:div, content_tag(:span,"Scheda informativa") + res)
  end

  def audio_visual_show_musicbrainz_artist(mba)
    return '' if mba.nil?
    res=[]
    mba.urls.each do |r|
      t,u=r
      u=[u] if u.class==String
      u.each do |url|
        res << content_tag(:li, link_to(t,url) + ' => ' + url)
      end
    end
    content_tag(:ol, res.join.html_safe)
  end

  def audio_visual_musicbrainz_query(record)
    return '' if record.autore.blank?
    # require 'musicbrainz'

    res=[]
    record.autore.split(';').each do |aut|
      stringa=aut.split(',').reverse.join(' ').strip
      a = MusicBrainz::Artist.find_by_name(stringa)
      next if a.nil?
      res << content_tag(:h3, %Q{Informazioni su <a href="http://musicbrainz.org/artist/#{a.id}"><b>#{stringa}</b></a> da MusicBrainz}.html_safe) +
        content_tag(:div, audio_visual_show_musicbrainz_artist(a))
    end
    content_tag(:div, res.join.html_safe)
  end

end
