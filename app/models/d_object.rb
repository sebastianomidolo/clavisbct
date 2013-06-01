include DigitalObjects

class DObject < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :references, :class_name=>'Attachment', :foreign_key=>'d_object_id'

  def read_metadata
    self.digital_object_read_metadata
    puts self.mime_type
    puts "filesize: #{bfilesize}"
    self.save if self.changed?
  end


  def get_pdfimage(n=1)
    n-=1
    return nil if (/^application\/pdf/ =~ self.mime_type).nil?
    f="#{self.pdf_rootname}-#{format('%03d',n)}.jpg"
    puts f
    File.exists?(f) ? f : nil
  end

  def pdf_rootdir
    File.join(self.digital_objects_cache,File.dirname(self.filename))
  end
  def pdf_rootname
    rootname=File.join(self.pdf_rootdir,File.basename(self.filename, File.extname(self.filename)))
  end
  def filename_with_path
    File.join(self.digital_objects_mount_point,self.filename)
  end

  def split_if_pdf
    return if (/^application\/pdf/ =~ self.mime_type).nil?
    FileUtils.mkdir_p(self.pdf_rootdir)
    cmd="/usr/bin/pdfimages -j \"#{self.filename_with_path}\" \"#{self.pdf_rootname}\""
    puts cmd
    Kernel.system(cmd)
    #Dir[(File.join(rootdir,'*'))].each do |entry|
    #  cmd="/usr/bin/convert \"#{entry}\" -resize 50% \"#{entry}\""
      # puts "cmd: #{cmd}"
    #  Kernel.system(cmd)
    #end

  end

  def xmltag(tag)
    tag=tag.to_s if tag.class==Symbol
    doc = REXML::Document.new(self.tags)
    elem=doc.root.elements[tag]
    elem.nil? ? nil : elem.text
  end

  def DObject.fs_scan(folder,fdout=nil)
    digital_objects_dirscan(File.join(digital_objects_mount_point, folder), fdout)
  end
end
