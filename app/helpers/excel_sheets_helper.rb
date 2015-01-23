module ExcelSheetsHelper

  def excel_sheet_show(record)
    res=[]
    record.excel_cells.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.cellname, excel_cell_path(r.id))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def excel_sheet_views(record)
    res=[]
    cnt=0
    record.views.each do |v|
      cnt+=1
      res << content_tag(:li, link_to(v[:name],view_excel_sheet_path(record,view: cnt)))
    end
    return 'x' if cnt==0
    content_tag(:ul, res.join.html_safe)
  end

  def excel_sheet_headings(sheet,view_number=nil)
    res=[]
    tdd=[]
    cnt=0
    sheet.sql_columns(view_number).each do |c|
      if c=="excel_cell_row"
        tdd << content_tag(:td, '')
      else
        colno=view_number.nil? ? "(#{cnt})" : ''
        tdd << content_tag(:td, link_to(%Q{#{c.gsub('"','')}#{colno}},excel_sheet_path(sheet,{group:cnt,view_number:view_number})))

      end
      cnt+=1
    end
    content_tag(:tr, tdd.join.html_safe)
  end

  def excel_sheet_records_group_by(sheet,records,column_number,view_number=nil)
    res=[]
    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    records.each do |r|
      lnk=link_to(r['col'],excel_sheet_path(sheet,{qs:r['col'],
                                              column_number:column_number,
                                              view_number:view_number}))
      res << content_tag(:tr, content_tag(:td, lnk) +
                         content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def excel_sheet_records(sheet,records,view_number=nil)
    res=[]
    res << content_tag(:tr, excel_sheet_headings(sheet,view_number))
    records.each do |r|
      tdd=[]
      cnt=0
      sheet.sql_columns(view_number).each do |c|
        cnt+=1
        if c=='"manifestation_id"'
          mid=r[c.gsub('"','')].to_i
          if mid!=0
            content="Vedi notizia #{mid} in Clavis: #{ClavisManifestation.find(mid).title}"
            lnk=ClavisManifestation.clavis_url(mid,:show)
            tdd << content_tag(:td, link_to(content,lnk))
          else
            tdd << content_tag(:td, "manca manifestation_id")
          end
        else
          if cnt==1
            tdd << content_tag(:td, link_to(r[c.gsub('"','')],
                                            excel_sheet_path(sheet, :row=>r['excel_cell_row'])))
          else
            content = r[c.gsub('"','')]
            content = link_to(content, content) if content =~ /^http/
            tdd << content_tag(:td, content)
          end
        end
      end
      res << content_tag(:tr, tdd.join.html_safe)
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def excel_sheet_breadcrumbs(excel_sheet,view_number=nil)
    res=[]
    res << content_tag(:li, link_to('Index', excel_files_path))
    res << content_tag(:li, link_to(File.basename(excel_sheet.excel_file.file_name),
                                    excel_file_path(excel_sheet.excel_file)))
    if !view_number.nil?
      res << content_tag(:li, link_to(excel_sheet.sheet_name,excel_sheet_path(excel_sheet)))
      res << content_tag(:li, excel_sheet.views[view_number-1][:name], class: 'active')
    else
      res << content_tag(:li, excel_sheet.sheet_name,class:'active')
    end
    content_tag(:ol, res.join.html_safe, class: 'breadcrumb')
  end

  def excel_sheet_row(excel_sheet,row_id)
    res=[]
    excel_sheet.load_row(row_id).each do |r|
      label,content=r
      next if content.blank? or label=='excel_cell_row'
      if label=='filename'
        lnk = link_to(content, d_objects_path(:filename=>content))
        res << content_tag(:tr, content_tag(:td, label) + content_tag(:td, lnk))
      else
        content = link_to(content, content) if content =~ /^http/
        res << content_tag(:tr, content_tag(:td, label) + content_tag(:td, content))
      end
    end
    content_tag(:table, res.join.html_safe, {class: 'table'})
  end

end
