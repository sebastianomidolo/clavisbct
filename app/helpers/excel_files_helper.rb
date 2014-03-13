module ExcelFilesHelper
  def excel_files_index(records)
    res=[]
    res << content_tag(:tr, content_tag(:th, 'Nome file') +
                         content_tag(:th, 'Numero di celle'))

    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(File.basename(r.file_name), excel_file_path(r))) +
                         content_tag(:td, r.number_of_cells))
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
