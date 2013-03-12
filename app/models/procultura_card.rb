class ProculturaCard < ActiveRecord::Base
  self.table_name = 'procultura.cards'
  belongs_to :folder, :class_name=>'ProculturaFolder'

  def fspath
    File.join(ProculturaCard.storagepath, self.filepath)
  end

  def extract_images(fmt)
    cpath=ProculturaCard.cachepath
    outfile=File.join(cpath, "#{self.id}.#{fmt}")
    if !File.exists?(outfile)
      cmd="/usr/bin/convert #{self.fspath} #{outfile}"
      Kernel.system(cmd)
    end
    true
  end

  def firstimage_path(fmt)
    cpath=ProculturaCard.cachepath
    fname=File.join(cpath, "#{self.id}.#{fmt}")
    return fname if File.exists?(fname)
    pattern=File.join(cpath, "#{self.id}-*.#{fmt}")
    Dir.glob(pattern).sort.first
  end

  def self.storagepath
    config = Rails.configuration.database_configuration
    config[Rails.env]['procultura_storage']
  end

  def self.cachepath
    config = Rails.configuration.database_configuration
    config[Rails.env]['procultura_cache']
  end

end
