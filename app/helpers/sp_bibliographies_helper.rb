module SpBibliographiesHelper
  def sp_bibliographies_list_old(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.title, build_link(sp_bibliography_path(r)))) +
                         content_tag(:td, r.status))
    end
    content_tag(:table, res.join.html_safe)
  end


  def sp_bibliographies_list(records)
    res=[]
    records.each do |r|
      # next if r.description.blank?
      res << render(:partial=>'/sp_bibliographies/shortview', :locals=>{:bibliography=>r})
    end
    res.join.html_safe
  end

  def sp_bibliography_show(record)
    res=[]
    res << content_tag(:h1, record.title)
    res << content_tag(:h2, record.subtitle)
    # res << sp_bibliography_short_description(record)
    res << SpBibliography.sanifica_html(record.html_description)
    res.join.html_safe
  end

  def sp_bibliography_cover_image(record)
    image_tag("https://#{request.host_with_port}#{cover_image_sp_bibliography_path(record)}") if !record.cover_image.nil?
  end

  def sp_bibliography_short_description(record)
    return '' if record.html_description.blank?
    res=SpBibliography.sanifica_html(record.html_description)

    i=res.index('<br')
    i = (i.nil? or i>100) ? 100 : i-1
    if res.length > 100
      add=' [...]'
    else
      add=''
    end
    content_tag(:div, "#{res[0..i]}#{add}".html_safe)
    # content_tag(:div, res.html_safe)
  end

  def sp_bibliography_check_items(record)
    res=[]
    record.sp_items.each do |i|
      begin
        cm=i.clavis_manifestation
      rescue
        cm_id="errore: #{i.id}"
      end
      if cm.nil?
        clavis_collciv=''
        clavis_colldec=''
        clavis_sigle=''
      else
        cm_id = cm.id
        info=cm.collocazioni_e_siglebib_per_senzaparola
        clavis_collciv=info['collciv']
        clavis_colldec=info['colldec']
        clavis_sigle=info['sigle']
        i.colldec.gsub!(' ', '.') if !i.colldec.blank?
        i.collciv.gsub!(' ', '.') if !i.collciv.blank?
        collciv_color = i.collciv!=clavis_collciv ? 'cyan' : 'white'
        colldec_color = i.colldec!=clavis_colldec ? 'cyan' : 'white'
        sigle_color = i.sigle!=clavis_sigle ? 'cyan' : 'white'
      end
      res << content_tag(:tr, content_tag(:td, cm_id) +
                         content_tag(:td, link_to(i.bibdescr[0..20], SpItem.senza_parola_item_path(i.item_id, i.bibliography_id))) +
                         content_tag(:td, "#{i.collciv}<br/><span style='background-color:#{collciv_color}'>#{clavis_collciv}</span>".html_safe) +
                         content_tag(:td, "#{i.colldec}<br/><span style='background-color:#{colldec_color}'>#{clavis_colldec}</span>".html_safe) +
                         content_tag(:td, "#{i.sigle}<br/><span style='background-color:#{sigle_color}'>#{clavis_sigle}</span>".html_safe))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

end


