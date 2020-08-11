class SerialLibrary < ActiveRecord::Base
  self.primary_keys = :serial_list_id, :clavis_library_id

  attr_accessible :sigla, :nickname

  before_save :set_date_updated

  def set_date_updated
    self.date_updated=Time.now
  end

  def self.clavis_libraries(serial_list_id, order_by)
    ClavisLibrary.find_by_sql("select * FROM #{self.table_name} sl join clavis.library cl on (cl.library_id=sl.clavis_library_id) where sl.serial_list_id=#{serial_list_id.to_i} order by #{order_by}")
  end

  def self.lista(serial_list_id)
    self.clavis_libraries(serial_list_id, "sigla")
  end
end
