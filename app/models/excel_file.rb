class ExcelFile < ActiveRecord::Base
  has_many :excel_sheets, order: :sheet_number
  def basename
    File.basename(self.file_name)
  end

  def config_filename
    self.file_name.sub(/.xls$/,'.yml')
  end
  def config_data
    File.exists?(self.config_filename) ? File.read(self.config_filename) : nil
  end
  def load_config
    d=self.config_data
    return {} if d.blank?
    YAML.load(d)
  end
  def write_config(config_data)
    puts "scrivo in #{self.config_filename}"
    File.open(self.config_filename, 'w') {|f| f.write(YAML.dump(config_data))}
  end

  def open_excel_file
    Roo::Excel.new(file_name)
  end

  def ExcelFile.summary
    # sql=%Q{SELECT ef.id,ef.file_name,count(*) as number_of_cells from excel_cells ec join excel_sheets es on(es.id=ec.excel_sheet_id) join excel_files ef on(ef.id=es.excel_file_id) group by ef.id,ef.file_name order by ef.file_name}
    sql=%Q{SELECT * from excel_files ef order by ef.file_name}
    # puts sql
    ExcelFile.find_by_sql(sql)
  end

end
