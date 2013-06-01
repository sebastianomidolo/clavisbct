module DObjectsHelper
  def d_object_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      v = (k=='bfilesize') ? "#{number_to_human_size(record[k])} (#{record[k]})" : record[k]
      res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, v))
    end
    record.references.each do |ref|
      path=ref.attachable.class.name.underscore + "_path"
      if self.respond_to?(path)
        link = link_to(ref.attachable.to_label, self.send(path, ref.attachable.id), :target=>'_blank')
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
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      lnk=d_objects_path(:mime_type=>r['mime_type'])
      n=number_to_human_size(r['bfilesize'])
      res << content_tag(:tr, content_tag(:td, link_to(r['mime_type'], lnk)) +
                         content_tag(:td, r['count']) +
                         content_tag(:td, n))
    end
    content_tag(:table, res.join.html_safe)
  end

  def d_objects_render(d_objects)
    res=[]
    audio=false
    cnt=0
    d_objects.each do |o|
      cnt+=1
      # res << image_tag(d_objects_path(o, :format=>'jpeg'))
      # res << content_tag(:div, d_objects_path(o))
      case o.mime_type.split(';').first
      when 'application/pdf'
        # res << content_tag(:div, link_to(o.filename, d_object_path(o, :format=>'pdf')))
        if !o.get_pdfimage.nil?
          # res << content_tag(:div, image_tag(d_object_path(o, :format=>'jpeg'), :size=>'100x100'))
          res << content_tag(:span, image_tag(d_object_path(o, :format=>'jpeg')))
        end
      when 'image/jpeg', 'image/tiff'
        res << content_tag(:li, image_tag(d_object_md5_link(o,:jpeg)))
        break if cnt>20
      when 'audio/mpeg'
        audio=true
        res << content_tag(:li, link_to(o.xmltag(:title), d_object_md5_link(o,:mp3)))
      else
        res << content_tag(:div, "non so che fare con questo: #{o.mime_type}")
      end
    end
    res << javascript_include_tag('http://webplayer.yahooapis.com/player.js') if audio
    # content_tag(:ul, res.join.html_safe, :style=>'width: 50%; padding: 3px; border: 4px outset green; list-style: none')
    content_tag(:ul, res.join.html_safe, :style=>'width: 80%; padding: 3px; border: 0px outset green; list-style: none')
  end

  def d_object_md5_link(record,extension='html')
    p=Digest::MD5.hexdigest(record.filename)
    "http://#{request.host_with_port}/obj/#{record.id}/#{p}.#{extension}?dng_user=#{params[:dng_user]}"
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
    
end
