class ExcelFile < ActiveRecord::Base
  has_many :excel_sheets, order: :sheet_number
  def basename
    File.basename(self.file_name)
  end
end
