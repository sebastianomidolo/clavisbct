class ExcelSheet < ActiveRecord::Base
  belongs_to :excel_file
  has_many :excel_cells, order: 'cell_row,cell_column'

  def columns
    sql=%Q{select cell_content as cc from public.excel_cells where excel_sheet_id = #{self.id} and cell_row=1}
    self.connection.execute(sql).collect {|r| r['cc']}
  end
  def to_label
    "#{self.excel_file.basename} => #{self.sheet_name}"
  end
end
