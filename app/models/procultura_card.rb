class ProculturaCard < ActiveRecord::Base
  self.table_name = 'procultura.cards'
  belongs_to :folder, :class_name=>'ProculturaFolder'

  def fspath
    File.join(ProculturaCard.storagepath, self.filepath)
  end

  def self.storagepath
    config = Rails.configuration.database_configuration
    config[Rails.env]['procultura_storage']
  end
end
