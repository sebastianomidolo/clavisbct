require 'filemagic'

FILENAME_METADATA_TAGS=[:au,:ti,:an,:mid,:pp,:uid,:sc,:dc]

module DigitalObjects
  def digital_objects_mount_point
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_mount_point"]
  end

  def digital_objects_cache
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_cache"]
  end

  def digital_objects_audioclips_dir
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_audioclips_dir"]
  end

  def get_fulltext_from_pdf
    return nil if (/^application\/pdf/ =~ self.mime_type).nil?
    # puts "ok"
    begin
      reader=PDF::Reader.new(self.filename_with_path)
    rescue
      puts "Errore: #{$!}"
      return {}
    end
    begin
      res=[]
      reader.pages.each do |p|
        puts p.class
        text=p.text
        next if text.blank?
        text.squish!
        res << text
      end
      {fulltext: res.join("\l")}
    rescue
      puts "errore #{$!}"
    end
  end

  # http://bctdoc.selfip.net/documents/30
  def get_bibdata_from_filename
    res={}
    self.filename.split('/').each do |part|
      part.split('#').each do |e|
        tag,data=e.split('_')
        # puts "tag #{tag} contiene '#{data}'"
        ts=tag.to_sym
        res[ts]=data if FILENAME_METADATA_TAGS.include?(ts) and !data.blank?
      end
    end
    res
  end

  def digital_objects_dirscan(dirname, fdout=nil)
    # puts "analizzo dir #{dirname}"
    fm=FileMagic.mime

    mp=digital_objects_mount_point
    filecount=0
    Dir[(File.join(dirname,'*'))].each do |entry|
      if File.directory?(entry)
        filecount += digital_objects_dirscan(entry, fdout)
      else
        fstat = File.stat(entry)
        mtype = fm.file(entry)
        if entry =~ /\.mp3$/i and mtype != 'audio/mpeg; charset=binary'
          puts "wrong mime type?: #{entry}"
        end

        entry.sub!(mp,'')
        # puts "File: #{entry}"
        filecount += 1
        if fdout.nil?
          DObject.find_or_create_by_filename(entry)
        else
          fdout.write("#{entry}\t#{fstat.size}\t#{fstat.ctime}\t#{fstat.mtime}\t#{fstat.atime}\t#{mtype}\n")
        end
      end
    end
    # puts "totale files: #{filecount}"
    filecount
  end

  def digital_object_read_metadata
    fm=FileMagic.mime
    fname = File.join(digital_objects_mount_point,filename)
    fstat = File.stat(fname)
    self.mime_type = fm.file(fname)
    self.bfilesize = fstat.size
    self.f_ctime = fstat.ctime
    self.f_mtime = fstat.mtime
    self.f_atime = fstat.atime
  end

  def libroparlato_audioclip_basename(ext='mp3')
    "audioclip_#{self.id}.#{ext}"
  end
  def libroparlato_audioclips_basedir
    config = Rails.configuration.database_configuration
    config[Rails.env]["libroparlato_audioclips_basedir"]
  end
  def libroparlato_audioclip_filename(ext='mp3')
    File.join(libroparlato_audioclips_basedir,libroparlato_audioclip_basename(ext))
  end

  def digital_object_create_libroparlato_audioclip(seconds=30,ext='mp3')
    return nil if self.mime_type!='audio/mpeg; charset=binary'
    fn=File.join(digital_objects_mount_point,self.filename)
    target=libroparlato_audioclip_filename(ext)
    return target if File.exists?(target) and File.size(target)>0
    cmd=%Q{/usr/bin/sox "#{fn}" "#{target}" trim 0 #{seconds} fade h 0 0:0:#{seconds} 4}
    # puts cmd
    Kernel.system(cmd)
    mp3=Mp3Info.open(target)
    mp3.tag2.TCOP="Biblioteche civiche torinesi - Servizio libro parlato"
    # mp3.tag2.WOAS="http://clavisbct.comperio.it/"
    mp3.tag2.TCON='Audiobook'
    mp3.tag2.COMM="Preascolto traccia audio"
    mp3.close
    target
  end

  def audioclips_basedir
    config = Rails.configuration.database_configuration
    config[Rails.env]["audioclips_basedir"]
  end

end
