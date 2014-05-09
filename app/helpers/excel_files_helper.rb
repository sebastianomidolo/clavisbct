module ExcelFilesHelper
  def excel_files_index(records)
    res=[]
    res << content_tag(:tr, content_tag(:th, 'Nome file') + content_tag(:th, 'File size')+
                       content_tag(:th, 'Ultima modifica'))
    records.each do |r|
      next if !File.exists?(r.file_name)
      size=File.size(r.file_name)
      lastmod=File.mtime(r.file_name)
      res << content_tag(:tr,
                         content_tag(:td, link_to(File.basename(r.file_name), excel_file_path(r))) +
                         content_tag(:td, number_to_human_size(size) +
                         content_tag(:td, lastmod.to_datetime))
                         )
    end
    content_tag(:table, res.join.html_safe)
  end

  def excel_file_show(record)
    res=[]
    res << content_tag(:h4, "Fogli disponibili:")
    li=[]
    record.excel_sheets.each do |r|
      vs=[]
      cnt=0
      r.views.each do |v|
        cnt+=1
        if r.tablename.nil?
          lnk=excel_sheet_path(r,view_number: cnt)
        else
          lnk=excel_sheet_path(id: r.tablename,view_number: cnt)
        end
        vs << content_tag(:li, link_to(v[:name],lnk) + " (#{r.sql_columns(cnt).join(', ')})")
      end
      vs = vs.size==0 ? '' : content_tag(:ul, vs.join.html_safe)
      lnk = r.tablename.nil? ? excel_sheet_path(r) : excel_sheet_path(id: r.tablename)
      li << content_tag(:li, link_to(r.sheet_name, lnk) + vs)
    end
    res << content_tag(:ul, li.join.html_safe)
    res.join.html_safe
  end

  def excel_file_breadcrumbs(excel_file)
    res=[]
    res << content_tag(:li, link_to('Index', excel_files_path))
    res << content_tag(:li, File.basename(excel_file.file_name), class: 'active')
    content_tag(:ol, res.join.html_safe, class: 'breadcrumb')
  end

end
