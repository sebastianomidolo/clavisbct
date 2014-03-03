class ExcelCell < ActiveRecord::Base
  belongs_to :excel_sheet

  def cellname
    "#{self.cell_column}#{self.cell_row}"
  end
  def row
    self.cell_row
    ExcelCell.all(conditions: {excel_sheet_id: self.excel_sheet_id,cell_row: self.cell_row},
                  order: 'cell_column::char')
  end
  def head
    ExcelCell.first(conditions: {excel_sheet_id: self.excel_sheet_id,cell_column: self.cell_column}).cell_content
  end
  def find_column(column)
    ExcelCell.where(excel_sheet_id: self.excel_sheet_id, cell_row: self.cell_row, cell_column: column).first
  end
  def content_of_column(column)
    r=self.find_column(column)
    r.nil? ? '' : r.cell_content
  end

end
