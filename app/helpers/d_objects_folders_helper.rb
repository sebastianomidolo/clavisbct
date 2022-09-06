# coding: utf-8
module DObjectsFoldersHelper
  def d_objects_folders_list(records)
    res=[]
    records.each do |f|
      if f.cover_image.blank?
        lnk = content_tag(:span, link_to(f.name,d_objects_folder_path(f)))
      else
        lnk = content_tag(:span, link_to(image_tag(view_d_object_path(f.cover_image, :format=>'jpeg', :size=>'250x')),
                                         d_objects_folder_path(f)))
      end
      # lnk = f.x_mid
      if !f.x_mid.blank? && f.x_mid.to_i > 0
        # clavis_title=link_to(ClavisManifestation.find(f.x_mid).title, ClavisManifestation.clavis_url(f.x_mid))
        clavis_title=link_to(ClavisManifestation.find(f.x_mid).title, clavis_manifestation_path(f.x_mid))
      else
        clavis_title=''
      end
      res << content_tag(:tr, content_tag(:td, lnk) + content_tag(:td, f.name) + content_tag(:td, clavis_title))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def d_objects_folder_show_cover_image(record)
    d_object=record.d_object_cover_image
    return '' if d_object.nil?
    link_to(image_tag(view_d_object_path(d_object, format:'jpeg', size:'400x')),
            view_d_object_path(d_object))
  end

  def d_objects_folder_split(record)
    res=[]
    record.split_path.each do |i|
      name,id=i
      if DObjectsFolder.find(id).readable_by?(current_user)
        res << link_to(name, d_objects_folder_path(id))
      else
        res << name
      end
    end
    res << content_tag(:b, d_objects_folder_editable_name(record))
    res.unshift(link_to('Oggetti digitali', d_objects_folders_path))
    content_tag(:h3, res.join('/').html_safe)
  end

  def d_objects_folder_dir(record)
    res=[]
    record.dir.each do |r|
      #lnk=link_to(r['dirname'], d_objects_folders_path(dirname:File.join(record.name, r['dirname'])))
      text = r.name.html_safe
      text += " <b>#{r.x_ti}</b>".html_safe if !r.x_ti.blank?
      text += " <b>[pdf]</b>".html_safe if !r.pdf_url.nil?
      text += " <b>manifestation_id #{r.x_mid}</b>".html_safe if !r.x_mid.blank?
      lnk=link_to(text, d_objects_folder_path(r.id))
      res << content_tag(:li, lnk)
    end
    content_tag(:ol, res.join.html_safe)
  end

  def d_objects_folders_root
    sql=%Q{SELECT pattern as basefolder,count(*) FROM d_objects_folders_users fu
      JOIN d_objects_folders f
        ON( (fu.d_objects_folder_id=f.id OR f.name || '/' LIKE fu.pattern || '%') AND fu.user_id=#{current_user.id})
        GROUP BY pattern order by lower(pattern)}
    res=[]
    ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
      f=content_tag(:h3, r['basefolder'])
      next if r['basefolder'].nil?
      f=r['basefolder'].chomp('/')
      res << content_tag(:tr, content_tag(:td, content_tag(:h3, link_to(f,d_objects_folders_path(dirname:f)))) +
                              content_tag(:td, r['count']))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def d_objects_folder_editable_name(record)
    return record.basename if !record.parent or !record.parent.writable_by?(current_user)
    # return "editable: #{record.basename} (#{record.id})"
    best_in_place(record, :basename, ok_button:'Salva', cancel_button:'Annulla',
                  ok_button_class:'btn btn-success',
                  class:'btn btn-default',
                  skip_blur:false,
                  html_attrs:{size:record.basename.size+10})
  end

  def d_objects_folder_list_content(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'Nome', class:'col-md-2') +
                            content_tag(:td, 'Dimensioni', class:'col-md-1') +
                            content_tag(:td, 'Tipo'))

    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(image_tag(view_d_object_path(r, :format=>'jpeg', :size=>'50x')),
                                          view_d_object_path(r))) +
                              content_tag(:td, r['name']) +
                              content_tag(:td, number_to_human_size(r['bfilesize'])) +
                              content_tag(:td, r['mime_type']))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
    
  end

  def d_objects_folder_pdf_info(record)
    res=[]
    record.access_right_id = 1 if record.access_right_id.nil?
    if record.access_right_id==0 and record.free_pdf_filename
      publ=true
    else
      publ=false
    end
    url=record.pdf_url
    fname=record.derived_pdf_filename
    if fname and File.readable?(fname)
      res << "Dimensioni del file PDF: #{number_to_human_size(File.size(fname))} (#{File.size(fname)} bytes), generato il #{File.ctime(fname).to_date}".html_safe
      if publ==true
        lnk="https://#{request.host_with_port}/getpdf/#{File.basename(record.free_pdf_filename)}"
      else
        lnk="https://#{request.host_with_port}#{derived_d_objects_folder_path(record,format:'pdf')}"
      end
      res << "<br/><b>#{record.access_right.description}:<br/>#{lnk}</b><br/>[#{link_to(lnk,lnk)}]".html_safe
    end
    res << "<br/>Parametri pdf: #{record.pdf_params}" if res.size>0
    res << "<br/>Fullpath: #{fname}" if res.size>0
    content_tag(:p, res.join("\n").html_safe)
  end

  def d_objects_folder_browse(record)
    return '' if record.parent.nil?
    lnks = []
    p = record.browse_object('prev')
    n = record.browse_object('next')
    if !p.nil?
      lnks << link_to('first', d_objects_folder_path(record.browse_object('first')))
      lnks << link_to('prev', d_objects_folder_path(p))
    else
      lnks << 'first'
      lnks << 'prev'
    end
    if !n.nil?
      lnks << link_to('next', d_objects_folder_path(n))
      last=record.browse_object('last')
      lnks << link_to('last', d_objects_folder_path(record.browse_object('last'))) if !last.nil?
    else
      lnks << 'next'
      lnks << 'last'
    end
    " [#{lnks.join('|')}]".html_safe
  end

  def d_objects_folder_references(record, limit=nil)
    res=[]
    limit = nil if limit==-1
    refs = limit.nil? ? record.references : record.references[0..limit-1]
    refs.each do |ref|
      path=ref.attachable.class.name.underscore + "_path"
      if self.respond_to?(path)
        link = link_to(ref.attachable.to_label, self.send(path, ref.attachable.id), :target=>'_blank')
      else
        link = ref.attachable.to_label
      end
      res << content_tag(:tr, content_tag(:td, ref.attachable.class) + content_tag(:td, link))
    end
    cnt = record.references.count
    if cnt > refs.count
      lnk = link_to('mostra tutti', d_objects_folder_path(record,refcount:-1))
      res << content_tag(:tr, content_tag(:td, '') + content_tag(:td, "(mostrati #{limit} su #{cnt} riferimenti) - #{lnk}".html_safe))
    end

    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def d_objects_folder_manifestation_ids_list(records)
    res = []
    records.each do |r|
      cm=ClavisManifestation.find(r['attachable_id'])
      ids=[]
      cm.d_objects.each do |o|
        ids << content_tag(:li, link_to(o.name, view_d_object_path(o.id)) + " data caricamento: #{o.f_mtime}")
      end
      link = link_to(cm.title, clavis_manifestation_path(cm), :target=>'_blank')
      res << content_tag(:tr, content_tag(:td, "#{r['count']} allegati per la stessa manifestation #{cm.id} (#{link}) <br/><ul>#{ids.join('')}</ul>".html_safe))
    end
    content_tag(:table, res.join.html_safe, {class: 'table'})
  end

end
