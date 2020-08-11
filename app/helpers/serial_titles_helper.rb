module SerialTitlesHelper

  def serial_titles_list_readonly(records)
    res=[]; cnt=0
    records.each do |r|
      library_names = params[:includi_bib].blank? ? '' : r.library_names
      num_tit = params[:numera_titoli].blank? ? '' : cnt+=1
      prezzo_stimato = params[:includi_prezzi].blank? ? '' : r.prezzo_stimato
      num_copie = params[:includi_numcopie].blank? ? '' : r.libraries.split(',').size
      note = r.note.blank? ? '' : "<br/><em>#{r.note}</em>"
      title="#{r.title}#{note}".html_safe
      res << content_tag(:tr, content_tag(:td, num_tit) +
                              content_tag(:td, title) +
                              content_tag(:td, prezzo_stimato) +
                              content_tag(:td, library_names) +
                              content_tag(:td, num_copie))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end

  def serial_titles_list(records)
    res=[]; cnt=0
    records.each do |r|
      lnk = r.count=='0' ? link_to('Elimina', r, method: :delete, data: { confirm: 'Confermi cancellazione titolo?' }) : ''
      note = r.note.blank? ? '' : "<br/><em>#{r.note}</em>"
      title=link_current_params("#{r.title}#{note}".html_safe, edit_serial_title_path(r), params)
      res << content_tag(:tr, content_tag(:td, cnt+=1) +
                              content_tag(:td, title) +
                              content_tag(:td, r.prezzo_stimato) +
                              content_tag(:td, link_current_params(r.library_names, serial_title_path(r), params)) +
                              content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end

  def serial_libraries_list(records)
    res=[]; cnt=0
    records.each do |r|
      if can? :manage, SerialList
        lnk = @serial_list.locked? ? '' : link_to('Elimina', delete_library_serial_list_path(@serial_list, library_id:r.library_id), method: :delete, data: { confirm: "Confermi cancellazione della biblioteca #{r.label} e di tutti i titoli e gli abbonamenti a essa collegata?" })
      else
        lnk = ''
      end
      res << content_tag(:tr, content_tag(:td, r.sigla) +
                              content_tag(:td, r.nickname) +
                              content_tag(:td, r.label) +
                              content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end
  
  def periodico_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k, class:'col-sm-2') + content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def periodici_import_list_files(sourcedir)
    files = []
    Dir[File.join(sourcedir,'*.txt')].sort.each do |entry|
      fname=File.basename(entry)
      files << link_to(fname, import_serial_list_path(sourcefile:fname))
    end
    content_tag(:pre, files.join("\n").html_safe)
  end

  def periodici_breadcrumbs
    # return "controller: #{params[:controller]} / action: #{params[:action]} - #{params.inspect}"
    links=[]

    # links << link_to('Liste periodici', serial_lists_path) if params[:controller]!='lperiodici'
    links << link_to('Liste periodici', serial_lists_path)

    if params[:controller]=='serial_titles' and ['new','create','edit','update','show','print'].include?(params[:action])
      links << link_current_params(@serial_list.to_label, serial_titles_path,params)
    end

    if params[:controller]=='serial_titles' and params[:action] = 'show' and !params[:id].blank?
      links << link_current_params(content_tag(:b, @serial_title.title), serial_title_path,params)
    end
    if params[:action]=='index' and !@serial_list.nil?
      links << link_current_params(@serial_list.to_label, serial_titles_path,params)
    end

    return '' if links.size==0

 
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

end
