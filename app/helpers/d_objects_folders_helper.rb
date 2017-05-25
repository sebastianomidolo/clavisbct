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
      if f.x_mid.to_i > 0
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
    return 'no cover' if d_object.nil?
    link_to(image_tag(view_d_object_path(d_object, format:'jpeg', size:'400x')),
            view_d_object_path(d_object))
  end
  def d_objects_folders_root
    sql=%Q{SELECT regexp_replace(name, '/.*', '') AS basefolder,count(*) FROM d_objects_folders f
       JOIN d_objects_folders_users fu
        ON( (fu.d_objects_folder_id=f.id OR f.name LIKE fu.pattern || '%') AND fu.user_id=#{current_user.id})
         where not name ~ '^/'
        group by basefolder order by basefolder}
    res=[]
    ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
      f=r['basefolder']
      res << content_tag(:tr, content_tag(:td, link_to(f,d_objects_folders_path(basefolder:f))) +
                              content_tag(:td, r['count']))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end
end
