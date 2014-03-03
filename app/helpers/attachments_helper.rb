module AttachmentsHelper

  def attachments_render(attachments)
    ct =attachments.group_by {|a| a.attachment_category_id}
    res=[]

    ct.each_pair do |category,allegati|
      # res << content_tag(:div, content_tag(:h2, attachment_category(category)))
      res << content_tag(:div, attachment_category(category))
      att=allegati.group_by {|a| a.folder}
      att.keys.sort.each do |k|
        res << content_tag(:div, content_tag(:b, k.capitalize)) if !k.nil? and !k.gsub(/CD/,'').blank?
        a=att[k]
        atc=a.sort {|x,y| x.position<=>y.position}
        dob=[]
        atc.each do |x|
          # res << content_tag(:h3, x.d_object.id)
          dob << x.d_object
        end
        if category=='E'
          dob.each do |d_ob|
            lista=d_object_tracklist(d_ob)
            if !lista.nil?
              res << content_tag(:div, content_tag(:ul, lista,
                                                   :style=>'width: 80%; padding: 0px; border: 0px outset green; list-style: none'))
            end
          end
        else
          res << content_tag(:div, d_objects_render(dob))
        end
      end
    end
    content_tag(:div, res.join.html_safe)
  end

  def attachment_category(ac)
    return nil if ac.nil?
    ac=AttachmentCategory.find(ac) if ac.class==String
    if ac.description.nil?
      content_tag(:span, ac.label)
    else
      content_tag(:span, ac.label) + content_tag(:span, "(#{ac.description})")
    end
  end

  def attachments_summary
    sql="select code,label,count(*) from attachments a join attachment_categories ac on (ac.code=a.attachment_category_id) group by code,label order by label;"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      lnk=d_objects_path(:attachment_category=>r['code'])
      res << content_tag(:tr, content_tag(:td, link_to(r['label'], lnk)) +
                         content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe)
  end

end
