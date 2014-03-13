class ExcelFile < ActiveRecord::Base
  has_many :excel_sheets, order: :sheet_number
  def basename
    File.basename(self.file_name)
  end
  def ExcelFile.summary
    sql=%Q{SELECT ef.id,ef.file_name,count(*) as number_of_cells from excel_cells ec join excel_sheets es on(es.id=ec.excel_sheet_id) join excel_files ef on(ef.id=es.excel_file_id) group by ef.id,ef.file_name order by ef.file_name}
    ExcelFile.find_by_sql(sql)
  end
end
