# coding: utf-8

module DObjectsHelper
  def d_object_editable_filename(record)
    return record.name if !record.writable_by?(current_user)
    best_in_place(record, :name, ok_button:'Salva', cancel_button:'Annulla',
                  ok_button_class:'btn btn-success',
                  class:'btn btn-default',
                  skip_blur:false,
                  html_attrs:{size:80})
  end

  def d_object_show(record)
    res=[]
    if !record.access_right_id.nil?
      res << content_tag(:tr, content_tag(:td, 'Accesso') + content_tag(:td, record.access_right.label))
    end
    keys=record.attributes.keys
    keys.delete('access_right_id')
    keys.delete('filename_old_style')
    keys.delete('filename') if !can? :search, DObject
    keys.sort.each do |k|
      next if record[k].blank?
      if k=='tags'
        if !(lista=d_object_tracklist(record)).nil?
          v=REXML::Document.new(record.tags).root.attributes.inspect
          res << content_tag(:tr, content_tag(:td, "Lista tracce #{v}") + content_tag(:td, content_tag(:ul, lista, :style=>'width: 100%; padding: 3px; border: 1px outset green; list-style: none'), :style=>'width: 100%'))
        else
          [:fulltext,:album,:title,:artist,:tracknumber,:au,:ti,:an].each do |tg|
            v=record.xmltag(tg)
            next if v.blank?
            res << content_tag(:tr, content_tag(:td, tg) + content_tag(:td, v))
          end
        end
        next
      end

      v = (k=='bfilesize') ? "#{number_to_human_size(record[k])} (#{record[k]})" : record[k]
      res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, v))
    end

    record.references.each do |ref|
      path=ref.attachable.class.name.underscore + "_path"
      if self.respond_to?(path)
        extra={}
        [:ac,:dng_user].each {|t| extra[t] = params[t] if !params[t].blank?}
        link = link_to(ref.attachable.to_label, self.send(path, ref.attachable.id, extra), :target=>'_blank')
      else
        link = ref.attachable.to_label
      end
      res << content_tag(:tr, content_tag(:td, ref.attachable.class) +
                         content_tag(:td, link))
    end
    res=content_tag(:table, res.join.html_safe)
  end
  def d_objects_summary
    sql="select mime_type,count(*),sum(bfilesize) as bfilesize from d_objects group by mime_type order by lower(mime_type)"
    sql="select mime_type,count(*),sum(bfilesize) as bfilesize from d_objects group by mime_type order by count(*) desc"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      lnk=d_objects_path(:mime_type=>r['mime_type'])
      n=number_to_human_size(r['bfilesize'])
      res << content_tag(:tr, content_tag(:td, link_to(r['mime_type'], lnk)) +
                              content_tag(:td, r['count']) +
                              content_tag(:td, r['bfilesize']) +
                              content_tag(:td, n))
    end
    content_tag(:table, res.join.html_safe)
  end

  def d_objects_render(d_objects, extra_params={})
    res=[]
    audio=false
    cnt=0
    if can? :search, DObject
      anonimo = false
    else
      anonimo = access_control_key.nil? ? true : false
    end
    dng_session=DngSession.find_by_params_and_request(params,request)
    if d_objects.class!=Array
      # Se non è un array, d_objects contiene un singolo id di d_object
      d_objects = [DObject.find(d_objects)]
      # return d_objects.inspect
    end
    d_objects.each do |o|
      #if o.mime_type.nil?
      #  o.read_metadata_da_cancellare
      #end
      cnt+=1
      # res << image_tag(d_objects_path(o, :format=>'jpeg'))
      # res << content_tag(:div, d_objects_path(o))
      case o.mime_type.split(';').first
      when 'application/pdf'
        o.pdf_to_jpeg if o.get_pdfimage.nil?
        if !o.get_pdfimage.nil?
          # res << content_tag(:div, image_tag(d_object_path(o, :format=>'jpeg'), :size=>'100x100'))
          # res << content_tag(:span, image_tag(d_object_path(o, :format=>'jpeg')))
          res << content_tag(:div, link_to(image_tag(d_object_md5_link(o,:jpeg, extra_params)),
                                           d_object_path(o, format:'pdf'))) if !anonimo
        end
      when 'image/jpeg', 'image/tiff', 'image/png'
        # res << content_tag(:li, d_object_md5_link(o,:jpeg))
        res << content_tag(:div, link_to(image_tag(d_object_md5_link(o,:jpeg, extra_params)),
                                         d_object_md5_link(o))) if !anonimo
      when 'audio/mpeg'
        text = o.xmltag(:title).blank? ? File.basename(o.filename) : o.xmltag(:title)
        if o.access_right_id==0 or (o.access_right_for(dng_session) and !anonimo)
          audio=true
          res << content_tag(:li, link_to(text, d_object_md5_link(o,:mp3),class:'audio_track',style:'display:none'))
        else
          res << content_tag(:li, "#{text} [#{o.access_right_to_label}]") if request.format=='text/html'
        end
      when 'application/msword'
        res << content_tag(:div, link_to('Download',d_object_path(o, :format=>'doc')))
      when 'audio/x-flac'
      else
        res << content_tag(:div, link_to("Scarica il file: #{o.mime_type}", download_d_object_path(o)))
      end
    end

    # res << javascript_include_tag('http://clavisbct.comperio.it/player.js') if audio
    # res << render(:partial=>'/d_objects/j_player') if audio
    res << render(:partial=>'/d_objects/j_player_new') if audio

    # content_tag(:ul, res.join.html_safe, :style=>'width: 50%; padding: 3px; border: 4px outset green; list-style: none')
    if anonimo and request.format=='text/html'
      content_tag(:ul, res.join.html_safe, :style=>'width: 80%; padding: 3px; border: 0px outset green;')
    else
      content_tag(:ul, res.join.html_safe, :style=>'width: 80%; padding: 3px; border: 0px outset green; list-style: none')
    end
  end

  def d_object_md5_link(record,extension='html',extra_params={})
    p=Digest::MD5.hexdigest(record.filename)
    ac=";ac=#{access_control_key}"
    extrap = []
    extra_params.each_pair do |k,v|
      extrap << "#{k}=#{v}"
    end
    extrap=extrap.join('&')
    "http://#{request.host_with_port}/obj/#{record.id}/#{p}.#{extension}?dng_user=#{params[:dng_user]}#{ac}&#{extrap}"
  end

  def rmagick_image_info(record)
    return if !['image/tiff','image/jpeg','application/pdf'].include?(record.mime_type.split(";")[0])
    im = Magick::Image::read(record.filename_with_path)
    img = im.first

    res=[]
    res << content_tag(:tr, content_tag(:td, 'Totale immagini') + content_tag(:td, im.size))
    if im.size>1
      res << content_tag(:tr, content_tag(:td, 'Informazioni sulla prima immagine') + content_tag(:td, ''))
    end
    res << content_tag(:tr, content_tag(:td, 'Format') + content_tag(:td, img.format))
    res << content_tag(:tr, content_tag(:td, 'Geometry') + content_tag(:td, "#{img.columns}x#{img.rows}"))
    res << content_tag(:tr, content_tag(:td, 'Class') + content_tag(:td, img.class_type))
    res << content_tag(:tr, content_tag(:td, 'Depth') + content_tag(:td, "#{img.depth} bits-per-pixel"))
    res << content_tag(:tr, content_tag(:td, 'Colors') + content_tag(:td, img.number_colors))
    res << content_tag(:tr, content_tag(:td, 'Filesize') + content_tag(:td, img.filesize))

    res << content_tag(:tr, content_tag(:td, 'Resolution') + content_tag(:td, "#{img.x_resolution.to_i}x#{img.y_resolution.to_i} pixels/#{img.units == Magick::PixelsPerInchResolution ? 'inch' : 'centimeter'}"))
    res=content_tag(:table, res.join.html_safe)
  end

  def d_object_tracklist(record)
    audio=false; lista=[]
    cnt=1
    record.get_tracklist.each do |track|
      # lista << content_tag(:li, record.audioclip_exists?(cnt))
      # lista << content_tag(:li, record.audioclip_filename(cnt))
      if record.audioclip_exists?(cnt)
        audio=true
        lista << content_tag(:li, link_to("#{track[:attributes]['position']}. #{track['title']}", %Q{http://#{request.host_with_port}#{d_object_path(record, format: 'mp3', t: cnt)}},class:'audio_track',style:'display:none'))
      else
        lista << content_tag(:li, "#{track[:attributes]['position']}. #{track['title']}")
      end
      cnt+=1
    end
    # lista << javascript_include_tag('http://clavisbct.comperio.it/player.js') if audio
    # lista << javascript_include_tag('http://bctwww.comperio.it/static/jPlayer/dist/jplayer/jquery.jplayer.min.js')
    # lista << javascript_include_tag('http://bctwww.comperio.it/static/jPlayer/dist/add-on/jplayer.playlist.js')
    lista << render(:partial=>'/d_objects/j_player_new') if audio
    lista.size==0 ? nil : lista.join.html_safe
  end

  def d_objects_view(records)
    res=[]
    res2=[]
    cnt=0
    records.each do |o|
      cnt+=1
      case o.mime_type.split(';').first
      when 'image/jpeg', 'image/tiff', 'image/png','application/pdf'
        res << content_tag(:span, link_to(image_tag(view_d_object_path(o, :format=>'jpeg', :size=>'150x')),
                                          view_d_object_path(o)))
      else
        res2 << content_tag(:li, link_to(o.name,view_d_object_path(o)))
      end
    end
    if res2.size>0
      res2 = content_tag(:ol, res2.join.html_safe)
    else
      res2 = ''
    end
    content_tag(:div, res.join.html_safe + res2)
  end

  def d_object_view_pdf(record)
    res=[]
    (1..record.pdf_count_pages).each do |page|
      res << content_tag(:span, link_to(image_tag(
                                          view_d_object_path(record, page:page, format:'jpeg', size:'250x'),
                                          style:'padding:1ex',class:'col-md-3 col-sm-4 col-lg'),
                                        view_d_object_path(record, page:page, format:'jpeg')))

    end
    content_tag(:div, res.join.html_safe)
  end


  def d_objects_filenames(records)
    res=[]
    cnt=0
    records.each do |o|
      cnt+=1
      res << content_tag(:tr, content_tag(:td, link_to('[vedi]',view_d_object_path(o))) +
                              content_tag(:td, d_object_editable_filename(o)))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

end
