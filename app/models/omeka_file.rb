class OmekaFile < OmekaRecord
  self.table_name='bcteka.files'
  after_destroy :delete_files

  attr_accessible :mime_type

  belongs_to :item, foreign_key: 'item_id', class_name:OmekaItem
  has_many :element_texts, foreign_key:'record_id', conditions:"record_type='File'", class_name:OmekaElementText

  def split_pdf
    extension=self.get_filename_extension
    return nil if extension!='.pdf'
    basename=self.filename.sub(extension,'')
    puts self.original_filename

    source=File.join(OmekaFile.storage_path, 'original', filename)
    dest=File.join(OmekaFile.storage_path, 'original', basename)
    cmd=%Q{/usr/bin/pdftk #{source} burst output #{dest}%04d.pdf}
    Kernel.system(cmd)

    i=1
    while true
      n=format "0%03d", i
      fname=File.join(OmekaFile.storage_path, 'original', "#{basename}#{n}.pdf")
      break if !File.exists?(fname)
      new_file=OmekaFile.create(fname, self.item.id, i)
      if new_file.class==OmekaFile
        new_file.derivate_images
      end
      i+=1
    end
  end

  def delete_files
    puts "CANCELLAZIONE FILES: #{self.filename}"
    img=File.join(OmekaFile.storage_path, 'original', self.filename)
    File.delete img
    basename=self.filename.sub(self.get_filename_extension,'')
    ['thumbnails','square_thumbnails','fullsize'].each do |p|
      img=File.join(OmekaFile.storage_path, p, basename) + '.jpg'
      if File.exists?(img)
        File.delete img
      end
    end
  end

  def derivate_images(pagenumber=0)
    extension=self.get_filename_extension
    return nil if !['.pdf','.jpeg','.tiff'].include?(extension)
    basename=self.filename.sub(extension,'')

    fullsize_file=File.join(OmekaFile.storage_path, 'fullsize', basename) + '.jpg'
    if extension == '.pdf'
      cmd = "/usr/bin/convert -density 300 #{self.original_path}[#{pagenumber}] -thumbnail x800 #{fullsize_file}"
    else
      cmd = "/usr/bin/convert -density 300 #{self.original_path} -thumbnail x800 #{fullsize_file}"
    end
    puts cmd
    Kernel.system(cmd) if !File.exists?(fullsize_file)

    ['thumbnails','square_thumbnails'].each do |p|
      img=File.join(OmekaFile.storage_path, p, basename) + '.jpg'
      destfile=File.join(OmekaFile.storage_path, p, basename) + '.jpg'
      case p
      when 'thumbnails'
        cmd = "/usr/bin/convert -density 300 #{fullsize_file} -thumbnail 200x #{destfile}"
      when 'square_thumbnails'
        cmd = "/usr/bin/convert -define jpeg:size=200x200 #{fullsize_file} -thumbnail 200x200^ -gravity center -extent 200x200 #{destfile}"
      end
      puts "cmd: #{cmd}"
      Kernel.system(cmd) if !File.exists?(destfile)
    end
    self.has_derivative_image=true
    self.save if self.changed?
  end

  def original_path
    File.join(OmekaFile.storage_path, 'original', self.filename)
  end

  def OmekaFile.storage_path
    config = Rails.configuration.database_configuration
    storage_path=config[Rails.env]['omeka_storage']
    return nil if storage_path.blank?
    storage_path
  end

  def get_filename_extension
    e=self.mime_type.split(';').first
    return nil if e.nil?
    e=e.split('/').last
    return nil if e.nil?
    ".#{e}"
  end

  # reload!;OmekaFile.upload_localfile(BctLetter.find(4).pdf_filename, OmekaItem.find(3))
  def OmekaFile.upload_localfile(filepath, omeka_item, order=1)
    puts "Carico il file #{filepath}"
    mime_type = FileMagic.mime.file(filepath)
    puts "mime_type: #{mime_type}"
    config = Rails.configuration.database_configuration
    storage_path=config[Rails.env]['omeka_storage']
    return nil if storage_path.blank?
    omeka_file=self.new(mime_type:mime_type)
    filename=SecureRandom.urlsafe_base64 + omeka_file.get_filename_extension
    lnkfname=File.join(storage_path, 'original', filename)
    puts filepath
    FileUtils.ln_s filepath, lnkfname
    data=File.read(filepath)
    md5sum=Digest::MD5.hexdigest(data)
    fsize=File.size(filepath)
    type_os=`file -b "#{filepath}"`.chomp

    puts self.connection.quote(File.basename(filepath))
    sql=%Q{INSERT INTO #{self.table_name} (item_id, "order", size, has_derivative_image, filename, original_filename,
          stored, metadata, authentication, mime_type, type_os)
      VALUES
      (#{omeka_item.id},#{order},#{fsize}, false, #{self.connection.quote(filename)},
       #{self.connection.quote(File.basename(filepath))}, true, '',
       #{self.connection.quote(md5sum)},
       #{self.connection.quote(mime_type)},
       #{self.connection.quote(type_os)});}
    puts sql
    self.connection.execute sql
    OmekaFile.find_by_filename(filename)
  end

  def OmekaFile.create(filepath, item_id, order)
    filename=File.basename(filepath)
    of=OmekaFile.find_by_filename(filename)
    return of if !of.nil?
    puts "Carico il file #{filepath}"
    mime_type = FileMagic.mime.file(filepath)
    puts "mime_type: #{mime_type}"
    omeka_file=self.new(mime_type:mime_type)
    data=File.read(filepath)
    md5sum=Digest::MD5.hexdigest(data)
    fsize=File.size(filepath)
    type_os=`file -b "#{filepath}"`.chomp


    sql=%Q{INSERT INTO #{self.table_name} (item_id, "order", size, has_derivative_image, filename, original_filename,
          stored, metadata, authentication, mime_type, type_os)
      VALUES
      (#{item_id},#{order},#{fsize}, false, #{self.connection.quote(filename)},
       #{self.connection.quote(filename)}, true, '',
       #{self.connection.quote(md5sum)},
       #{self.connection.quote(mime_type)},
       #{self.connection.quote(type_os)});}
    puts sql
    self.connection.execute sql
    # OmekaFile.find_by_filename(filename)
    OmekaFile.last
  end

end
