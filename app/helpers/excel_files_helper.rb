module ExcelFilesHelper
  def excel_files_index(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(File.basename(r.file_name), excel_file_path(r))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def excel_file_show(record)
    res=[]
    record.excel_sheets.each do |r|
      # res << content_tag(:tr, content_tag(:td, link_to(r.inspect), excel_sheet_path(r.id)))
      res << content_tag(:tr, content_tag(:td, link_to(r.sheet_name, excel_sheet_path(r))))
    end
    content_tag(:table, res.join.html_safe)
  end
end
