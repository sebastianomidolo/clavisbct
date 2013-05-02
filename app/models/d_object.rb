include DigitalObjects

class DObject < ActiveRecord::Base
  # attr_accessible :title, :body

  def read_metadata
    self.digital_object_read_metadata
    puts self.mime_type
    puts "filesize: #{bfilesize}"
    self.save if self.changed?
  end

  def split_if_pdf
    return if (/^application\/pdf/ =~ self.mime_type).nil?
    rootdir=File.join(self.digital_objects_cache,File.dirname(self.filename))
    FileUtils.mkdir_p(rootdir)
    rootname=File.basename(self.filename, File.extname(self.filename))
    rootname=File.join(rootdir,rootname)
    cmd="/usr/bin/pdfimages -j \"#{File.join(self.digital_objects_mount_point,self.filename)}\" \"#{rootname}\""
    puts cmd
    Kernel.system(cmd)
    #Dir[(File.join(rootdir,'*'))].each do |entry|
    #  cmd="/usr/bin/convert \"#{entry}\" -resize 50% \"#{entry}\""
      # puts "cmd: #{cmd}"
    #  Kernel.system(cmd)
    #end

  end


  def DObject.fs_scan(folder,fdout=nil)
    digital_objects_dirscan(File.join(digital_objects_mount_point, folder), fdout)
  end
end
