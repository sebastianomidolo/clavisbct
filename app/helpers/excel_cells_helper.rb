module ExcelCellsHelper

  def excel_cell_show(record)
    res=[]
    s=record.excel_sheet
    res << content_tag(:h2, link_to(s.to_label,excel_sheet_url(s)))
    res << content_tag(:h3, record.cell_content)
    res << content_tag(:p, excel_cell_show_row(record))
    res.join.html_safe
  end

  def excel_cell_show_row(record)
    res=[]
    record.row.each do |r|
      fieldname=r.head
      if fieldname=='manifestation_id'
        manifestation_id=r.cell_content.to_i
        if manifestation_id!=0
          content="Vedi notizia #{manifestation_id} in Clavis: #{ClavisManifestation.find(manifestation_id).title}"
          lnk=ClavisManifestation.clavis_url(manifestation_id,:show)
        else
          content=r.cell_content
          lnk=excel_sheet_url(r.excel_sheet_id, cell_column: r.cell_column)
        end
      else
        content=r.cell_content
        lnk=excel_sheet_url(r.excel_sheet_id, cell_column: r.cell_column)
      end
      res << content_tag(:tr, content_tag(:td, r.cellname) +
                         content_tag(:td, link_to(r.head,lnk)) +
                         content_tag(:td, content))
    end
    content_tag(:table, res.join.html_safe)
  end

  def excel_cells_list(cells,cell_column)
    res=[]
    res << content_tag(:pre, "#{cells.to_sql};")
    res << content_tag(:div, "=> #{cells.to_a.size}")
    cells.each do |c|
      if cell_column.blank?
        res << content_tag(:div, excel_cell_show_row(c), :style=>"border-bottom: 1px solid black")
      else
        res << content_tag(:div, link_to(c.content_of_column(cell_column),excel_cell_url(c)), :style=>"border-bottom: 1px solid black")
      end
    end
    res.join.html_safe
  end

end
