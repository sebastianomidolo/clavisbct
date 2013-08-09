require 'filemagic'

FILENAME_METADATA_TAGS=[:au,:ti,:an,:mid,:pp,:uid,:sc]

module DigitalObjects
  def digital_objects_mount_point
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_mount_point"]
  end

  def digital_objects_cache
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_cache"]
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
    fname = File.join(digital_objects_mount_point,filename)
    fstat = File.stat(fname)
    puts fstat.inspect
    puts "id: #{id}"
    puts self.attributes
    self.bfilesize = File.size(fname)
  end

end
