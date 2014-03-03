module ExcelSheetsHelper

  def excel_sheet_show(record)
    res=[]
    record.excel_cells.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.cellname, excel_cell_path(r.id))))
    end
    content_tag(:table, res.join.html_safe)
  end
end
