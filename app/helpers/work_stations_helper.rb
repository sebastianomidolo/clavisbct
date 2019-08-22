module WorkStationsHelper
  def work_station_managed_bookmarks_edit(record)
    res=[]
    res << content_tag(:tr, content_tag(:td, "Homepage") + content_tag(:td, text_field_tag("homepage", record.homepage, size:80)))
    cnt=0    
    record.managed_bookmarks.each do |r|
      url,label=r.split('|')
      label.gsub!('_', ' ') if !label.blank?
      edit_label=text_field_tag "label[#{cnt}]", label, size:40
      edit_url=text_field_tag "url[#{cnt}]", url, size:80
      res << content_tag(:tr, content_tag(:td, edit_label) + content_tag(:td, edit_url))
      cnt+=1
    end
    edit_label=text_field_tag "label[#{cnt}]", '', size:40
    edit_url=text_field_tag "url[#{cnt}]", '', size:80
    res << content_tag(:tr, content_tag(:td, edit_label) + content_tag(:td, edit_url))

    res << content_tag(:tr, content_tag(:td, submit_tag('Salva'))  + content_tag(:td, 'Annulla'))
    form=form_tag(bookmarks_save_work_station_path(record), method:'put')
    
    table=content_tag(:table, res.join.html_safe,class:'table')
    form+table
  end
end
