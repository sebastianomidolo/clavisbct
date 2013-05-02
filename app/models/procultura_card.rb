require 'RMagick'
class ProculturaCard < ActiveRecord::Base
  self.table_name = 'procultura.cards'
  belongs_to :folder, :class_name=>'ProculturaFolder'
  has_many :attachments, :as => :attachable

  def to_label
    "\##{self.id} #{self.folder.label} in #{self.folder.archive.name}"
  end

  def fspath
    File.join(ProculturaCard.storagepath, self.filepath)
  end

  def extract_images_old(fmt)
    cpath=ProculturaCard.cachepath
    outfile=File.join(cpath, "#{self.id}.#{fmt}")
    if !File.exists?(outfile)
      cmd="/usr/bin/convert #{self.fspath} #{outfile}"
      Kernel.system(cmd)
    end
    true
  end
  def intestazione
    self.heading.blank? ? 'senza intestazione' : self.heading
  end
  def get_image(fmt)
    cpath=ProculturaCard.cachepath
    outfile=File.join(cpath, "#{self.id}.#{fmt}")
    if !File.exists?(outfile)
      puts "ricavo #{outfile} da #{self.fspath}"
      fn=self.to_netpbm
      i=Magick::Image.read(fn).first
      i.write(outfile)
    end
    true
  end

  def to_netpbm
    cpath=ProculturaCard.cachepath
    outfile=File.join(cpath, "#{self.id}.pbm")
    img_root=File.join(cpath, "#{self.id}")
    if !File.exists?(outfile)
      cmd="/usr/bin/pdfimages -f 1 -l 1 #{self.fspath} #{img_root}"
      Kernel.system(cmd)
      pbm_file=File.join(cpath, "#{self.id}-000.pbm")
      File.rename(pbm_file, outfile)
    end
    puts outfile
    outfile
  end


  def magick_image
    Magick::Image.read(self.fspath).first
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
