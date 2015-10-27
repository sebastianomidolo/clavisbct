require 'RMagick'
class ProculturaCard < ActiveRecord::Base
  self.table_name = 'procultura.cards'
  attr_accessible :heading, :updated_by, :updated_at, :sort_text

  belongs_to :updated_by, class_name: 'User', foreign_key: :updated_by

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
    self.heading.blank? ? '(intestazione in fase di revisione)' : self.heading
  end
  def updated_by_info
    return '' if self.updated_by.nil?
    "#{self.updated_by.email} #{self.updated_at.to_date}"
  end

  def cached_filename(fmt)
    cpath=ProculturaCard.cachepath
    File.join(cpath, "#{self.id}.#{fmt}")
  end
  def get_image(fmt)
    outfile=self.cached_filename(fmt)
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
    # puts outfile
    outfile
  end

  def minuscolizza_intestazione
    puts "archivio: #{self.folder.archive.id}"
    h=self.heading
    puts h
    wd=self.heading.split
    case self.folder.archive.id
    when 1,2
      # (titoli e soggetti)
      # => Solo l'iniziale maiuscola, il resto minuscolo
      self.heading.capitalize
    when 3
      case wd.size
      when 3

      when 2
        "due"
      when 1
        "uno"
      else
        "non so"
      end
    end
  end


  def minuscolizza_intestazione!
    self.heading=self.minuscolizza_intestazione and self.save
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

  def self.lista_alfabetica(conditions, params)
    sql=%{select c.*,a.name as archive_name, f.label as folder_label, f.id as folder_id
     from procultura.cards c join procultura.folders f on (f.id=c.folder_id)
       join procultura.archives a on(a.id=f.archive_id) where #{conditions} order by lower(c.sort_text)}
    # ProculturaCard.paginate(conditions:conditions,page:params[:page],per_page:params[:per_page],order:'lower(sort_text)')
    ProculturaCard.paginate_by_sql(sql,page:params[:page],per_page:params[:per_page])
  end

end
