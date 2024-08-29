# coding: utf-8
module SpItemsHelper
  def sp_item_show(record)
    res=[]
    style="margin-left: 20px"
    res << content_tag(:p, record.mainentry, style: 'font-size: 120%; font-weight:bold') if !record.mainentry.blank?
    res << content_tag(:span, record.to_html.html_safe, style: 'font-size: 100%')
    res << content_tag(:p, "Collocazione: <b>#{record.collocazioni}</b>".html_safe,style: 'font-size: 120%') if !record.collocazioni.blank?
    res << content_tag(:p, "Note: <em>#{record.note}</em>".html_safe,style: 'font-size: 100%') if !record.note.blank?
    res << content_tag(:div, clavis_manifestation_opac_preview(record.clavis_manifestation)) if !record.clavis_manifestation.nil?
    res.join.html_safe
  end

  def sp_item_show_short(record)
    res=[]
    style="margin-left: 20px"
    res << content_tag(:span, "#{record.mainentry}. ".html_safe, style: 'font-size: 110%; font-weight:bold') if !record.mainentry.blank?
    res << content_tag(:span, record.bibdescr.html_safe, style: 'font-size: 100%')
    content_tag(:p, res.join.html_safe)
  end

  def sp_items_list_items(sp_items)
    return sp_items_list_items_logged_in(sp_items) if !current_user.nil?
    res=[]
    sp_items.each do |i|
      image = i.manifestation_id.nil? ? '' : link_to(image_tag(dnl_d_object_path(1, format:'jpeg', manifestation_id:i.manifestation_id,size:'200x')),build_link(sp_item_path(i)))
      # txt = i.mainentry.blank? ? i.to_html : "<b>#{i.mainentry}.</b>  #{i.to_html}"
      txt = i.mainentry.blank? ? i.bibdescr : "<b>#{i.mainentry}.</b>  #{i.bibdescr}"
      txt = '[senza titolo]' if txt.blank?
      note = i.note.blank? ? '' : "<br/><em>#{i.note}</em>"
      res << content_tag(:tr, content_tag(:td, image) +
                              content_tag(:td,
                                          link_to(SpBibliography.latex2html(txt).html_safe,
                                                  build_link(sp_item_path(i))) + note.html_safe) +
                              content_tag(:td, i.collciv))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def sp_items_list_items_logged_in(sp_items)
    return 'error' if current_user.nil?
    res=[]
    sp_items.each do |i|
      image = i.manifestation_id.nil? ? '' : link_to(image_tag(dnl_d_object_path(1, format:'jpeg', manifestation_id:i.manifestation_id,size:'200x')),build_link(sp_item_path(i)))
      # txt = i.mainentry.blank? ? i.to_html : "<b>#{i.mainentry}.</b>  #{i.to_html}"
      txt = i.mainentry.blank? ? i.bibdescr : "<b>#{i.mainentry}.</b>  #{i.bibdescr}"
      txt = '[senza titolo]' if txt.blank?
      note = i.note.blank? ? '' : "<br/><em>#{i.note}</em>"
      lnk = build_link(sp_item_path(i))
      clavislnk = i.manifestation_id.nil? ? '' : link_to('[clavis]', ClavisManifestation.clavis_url(i.manifestation_id.to_i, :edit))
      res << content_tag(:tr, content_tag(:td, image) +
                              content_tag(:td, clavislnk) +
                              content_tag(:td, link_to(SpBibliography.latex2html(txt).html_safe, lnk) + note.html_safe) +
                              content_tag(:td, i.collciv))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  
  def sp_items_ricollocati_a_scaffale_aperto(sp_items)
    res=[]
    sp_items.each do |i|
      res << content_tag(:tr, content_tag(:td,
                                          link_to(i.bibdescr, i.senza_parola_item_path,target:'_new'),
                                          style:'width:50%') +
                         content_tag(:td, i.ex_collocazione) +
                         content_tag(:td, i.section) +
                         content_tag(:td, i.collocation) +
                         content_tag(:td, i.bibliography_title))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sp_item_clavis_info(sp_item)
    cm=sp_item.clavis_manifestation
    return 'non trovato in Clavis' if cm.nil?
    r=cm.collocazioni_e_siglebib_per_senzaparola
    info="collciv: #{r['collciv']}<br/>colldec: #{r['colldec']}<br/>sigle: #{r['sigle']}"
    content_tag(:div, clavis_manifestation_opac_preview(cm) +
                content_tag(:div, link_to('Clavis gestionale', cm.clavis_url(:show))) +
                content_tag(:div, info.html_safe) +
                clavis_manifestation_show_items(cm))
  end

  def sp_item_attachments_show(sp_item,page=nil)
    return if sp_item.clavis_manifestation.nil?
    res = []
    cnt = 0
    cm = sp_item.clavis_manifestation

    d_objects = []
    cm.attachments.order(:position).each do |a|
      d_object = DObject.find(a.d_object_id)
      next if d_object.access_right_id!=0
      cnt += 1
      # res << content_tag(:h5, "#{cnt}. manifestation_id: #{cm.id} - pos: #{a.position} - ( #{link_to(d_object.id,view_d_object_path(d_object.id))} ) #{d_object.name} - #{d_object.mime_type} access_right_id: #{d_object.access_right_id} - #{a.attachment_category_id}".html_safe)
      if d_object.mime_type =~ /^application\/pdf/
        titolo_sezione=content_tag(:h5, "#{link_to(d_object.name, sp_item_path(sp_item,d_object:d_object,page:1),class:'btn btn-success')}".html_safe)
        res << content_tag(:div, titolo_sezione + sp_item_d_object_view_pdf(sp_item,d_object,6), class:'imgdiv-esterno clearfix')
      else
        d_objects << d_object if a.attachment_category_id!='F'
      end
    end
    # return d_objects.size
    if res == []
      f = cm.d_objects_folders.first
      # return cm.id
      if f.nil?
        # return sp_item_d_objects_view(sp_item, d_objects)
        # return "Visualizzo già grande questi oggetti: #{d_objects.inspect}"
        d_objects.each do |o|
          imgpath = dnl_d_object_path(o, :format=>'jpeg', :size=>'900x')
          res << content_tag(:span, link_to(image_tag(imgpath), dnl_d_object_path(o, :format=>'jpeg')), {style:'display:block;margin-top:22px'})
        end
        return res==[] ? "\n<!-- non ci sono immagini associate -->\n".html_safe : content_tag(:div, res.join.html_safe)
      else
        # return f.id
        retval = sp_item_d_objects_view(sp_item, f.d_objects)
        retval2 = []
        d_objects -= f.d_objects
        d_objects.each do |o|
          imgpath = dnl_d_object_path(o, :format=>'jpeg', :size=>'900x')
          retval2 << content_tag(:span, link_to(image_tag(imgpath), dnl_d_object_path(o, :format=>'jpeg')), {style:'display:block;'})
        end
        if retval2 == []
          return retval
        else
          return content_tag(:p, retval) + content_tag(:p, retval2.join.html_safe)
        end
      end
    else
      return res.join("\n").html_safe
    end
  end

  def sp_item_d_objects_browse(sp_item, d_object, page=nil)
    # return "eccomi, sp_item.class: #{d_object.mime_type} - page: #{page}"
    lnks = []
    btf = ' |< '
    btp = ' < '
    btn = ' > '
    btl = ' >| '
    ccss = 'label label-info'
    if !page.nil?
      page = page.to_i
      p = d_object.browse_object('prev',page)
      n = d_object.browse_object('next',page)
      if !p.nil?
        lnks << link_to(btf, sp_item_path(sp_item,d_object:d_object,page:1))
        # lnks << link_to(content_tag(:span, btf, class:ccss, title:"vai alla prima pagina"), sp_item_path(sp_item,d_object:d_object,page:1))
        lnks << link_to(btp, sp_item_path(sp_item,d_object:d_object,page:p))
      else
        lnks << btf
        lnks << btp
      end
      if !n.nil?
        lnks << link_to(btn, sp_item_path(sp_item,d_object:d_object,page:n))
        lnks << link_to(btl, sp_item_path(sp_item,d_object:d_object,page:d_object.browse_object('last',page)))
      else
        lnks << btn
        lnks << btl
      end
    else
      p = d_object.browse_object('prev')
      n = d_object.browse_object('next')
      if !p.nil?
        lnks << link_to(btf, sp_item_path(sp_item,d_object:d_object.browse_object('first')))
        lnks << link_to(btp, sp_item_path(sp_item,d_object:p))
      else
        lnks << btf
        lnks << btp
      end
      if !n.nil?
        lnks << link_to(btn, sp_item_path(sp_item,d_object:n))
        last=d_object.browse_object('last')
        lnks << link_to(btl, sp_item_path(sp_item,d_object:last)) if !last.nil?
      else
        lnks << btn
        lnks << btl
      end
    end
    # content_tag(:p, " #{lnks.join(' ')}".html_safe, {class:'label label-info browse_item_d_objects'})
    content_tag(:span, " #{lnks.join(' ')}".html_safe, {class:'label label-info'})
    # content_tag(:span, "#{lnks.join('')}".html_safe, class:ccss)
  end

  def sp_item_d_objects_view(sp_item, records)
    records = [records] if records.class != Array
    res=[]
    res2=[]
    cnt=0
    records.each do |o|
      cnt+=1
      case o.mime_type.split(';').first
      when 'image/jpeg', 'image/tiff', 'image/png','application/pdf'
        next if current_user.nil? and o.access_right_id!=0
        imgpath = dnl_d_object_path(o, :format=>'jpeg', :size=>'300x', crop:true)
        res << content_tag(:span, link_to(image_tag(imgpath,style:'padding:1ex',class:'col-sm-4 col-md-3 col-lg-2'), sp_item_path(sp_item, d_object:o)))
      else
        next if o.access_right_id!=0 and current_user.nil?
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

  def sp_item_d_object_view_pdf(sp_item, d_object, max=nil)
    if current_user.nil? and d_object.access_right_id!=0
      return 'no access'
    end
    d_object.get_pdfimage
    max = d_object.pdf_count_pages if max.nil? or max>d_object.pdf_count_pages
    res=[]
    (1..max).each do |page|
      imgpath = dnl_pdf_d_object_path(d_object, page:page, :format=>'jpeg', :size=>'300x', crop:true)
      link = sp_item_path(sp_item, d_object:d_object, page:page)
      res << content_tag(:span, link_to(image_tag(imgpath,style:'padding:1ex',class:'col-sm-4 col-md-3 col-lg-2'), link))
    end
    # content_tag(:div, res.join("\n").html_safe, class:'imgdiv-interno', style:'align:right !important')
    content_tag(:div, res.join("\n").html_safe, class:'imgdiv-interno')
  end
                        
  def sp_items_browse(record)
    lnks = []
    ccss = 'label label-info'
    btf = ' << '
    btp = ' < '
    btn = ' > '
    btl = ' >> '
    p = record.previous_item
    n = record.next_item
    if !p.nil?
      lnks << link_to(content_tag(:span, btf, class:ccss), sp_item_path(record.first_item))
      lnks << link_to(content_tag(:span, btp, class:ccss), sp_item_path(p))
    else
      lnks << content_tag(:span, btf, class:ccss)
      lnks << content_tag(:span, btp, class:ccss)
    end
    if !n.nil?
      lnks << link_to(content_tag(:span, btn, class:ccss), sp_item_path(n))
      last=record.last_item
      lnks << link_to(content_tag(:span, btl, class:ccss), sp_item_path(record.last_item)) if !last.nil?
    else
      lnks << content_tag(:span, btn, class:ccss)
      lnks << content_tag(:span, btl, class:ccss)
    end
    # content_tag(:span, " #{lnks.join(' ')}".html_safe, {class:'browse_items'})
    content_tag(:span, "#{lnks.join('')}".html_safe, class:ccss)
  end

end
