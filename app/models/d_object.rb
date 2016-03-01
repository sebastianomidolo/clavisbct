require 'RMagick'

include DigitalObjects
require 'rexml/document'
require 'mp3info'


class DObject < ActiveRecord::Base
  attr_accessible :filename, :access_right_id, :mime_type, :tags
  has_many :references, :class_name=>'Attachment', :foreign_key=>'d_object_id'
  belongs_to :access_right
  before_save :check_filesystem
  after_destroy do |record|
    puts "record con id #{record.id} - cancellare file #{record.filename_with_path}"
    File.delete record.filename_with_path
  end

  def check_filesystem
    self.digital_object_read_metadata
  end

  def read_metadata_da_cancellare
    self.digital_object_read_metadata
    puts self.mime_type
    puts "filesize: #{bfilesize}"
    self.save if self.changed?
  end

  def access_right_to_label
    self.access_right_id.nil? ? 'diritti non specificati' : self.access_right.description
  end

  def access_right_for(dng_session)
    case self.access_right_id
    when 0
      true
    when 1
      false
    when 2
      dng_session.nil? ? false : dng_session.patron.autorizzato_al_servizio_lp
    else
      false
    end
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
    if !(/^\// =~ self.filename)
      File.join(self.digital_objects_mount_point,self.filename)
    else
      self.filename
    end
  end

  def pdf_to_jpeg
    return [] if self.mime_type!='application/pdf; charset=binary'
    if !File.exists?(self.pdf_rootdir)
      FileUtils.mkdir_p(self.pdf_rootdir)
    end
    filelist=[]
    img=Magick::Image.read(self.filename_with_path)
    cnt=1
    img.each do |i|
      jpegfile="#{self.pdf_rootname}_#{cnt}.jpeg"
      i.write(jpegfile)
      cnt+=1
      filelist << jpegfile
    end
    filelist
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

  def write_tags_from_filename
    self.tags=self.get_bibdata_from_filename.to_xml(:root=>:r,:skip_instruct=>true,:indent=>0)
    self.save if self.changed?
  end

  def write_fulltext_from_pdf
    ft=self.get_fulltext_from_pdf
    return nil if ft.blank?
    self.tags=ft.to_xml(:root=>:r,:skip_instruct=>true,:indent=>0)
    self.save if self.changed?
  end


  def xmltag(tag)
    tag=tag.to_s if tag.class==Symbol
    return nil if self.tags.nil?
    doc = REXML::Document.new(self.tags)
    elem=doc.root.elements[tag]
    elem.nil? ? nil : elem.text
  end

  def parent_folder
    Pathname.new(File.expand_path("..",self.filename)).split.last.to_s
  end

  def parent_folder_with_metadata?
    if DObject.includes_metadata_tags?(self.parent_folder)
      true
    else
      false
    end
  end

  def audioclip_exists?(cnt=1)
    File.exists?(self.audioclip_filename(cnt))
    # (!r and cnt==1) ? File.exists?(self.audioclip_filename) : r
  end
  def audioclip_filename(cnt=1)
    dir=File.dirname(File.join(self.audioclips_basedir, self.filename).sub('bm::',''))
    basename=File.basename(self.filename)
    f=File.join(dir, format("%03d%s", cnt, '.mp3'))
    puts "clip?: #{f}"
    fname = File.exists?(f) ? f : File.join(dir,basename)
    puts "audioclip per #{self.id} traccia #{cnt}: #{fname}"
    fname
  end

  def edit_tags(hash)
    doc=REXML::Document.new(self.tags)
    # puts "in edit_tags, prima: #{doc.to_s}"
    hash.each_pair do |k,v|
      t=k.to_s
      el = doc.root.elements[t]
      # puts "el: #{el.class} => '#{el.to_s}'"
      doc.root.elements.delete(el) if !el.nil?
      el=REXML::Element.new(t)
      el.add_text(v)
      doc.root.elements << el
    end
    # puts "in edit_tags, dopo: #{doc.to_s}"
    self.tags=doc.to_s
  end

  def get_tracklist
    return [] if self.tags.nil?
    doc = REXML::Document.new(self.tags)
    return [] if doc.root.name!='tracklist'
    res=[]
    doc.root.elements.each do |e|
      cnt=e.attributes['position'].blank? ? nil : e.attributes['position'].to_i
      res << {e.name => e.text, attributes: e.attributes, :audioclip=>self.audioclip_exists?(cnt)}
    end
    res
  end

  def DObject.to_pdf(ids,pdf_filename)
    # return true if File.exists?(pdf_filename)
    logo = Magick::Image.read("/home/storage/preesistente/testzone/bctcopyr.gif").first
    iList =  Magick::ImageList.new
    ids.each do |o|
      # puts o.filename
      img=Magick::Image.read(o.filename_with_path).first
      img.resize_to_fit!(2000)
      img=img.watermark(logo,0.1,0.5,Magick::NorthGravity,0,0)
      img=img.watermark(logo,0.9,0.5,Magick::SouthGravity,0,0)
      iList << img
    end
    iList.write(pdf_filename)
    iList.each {|i| i.destroy!}
    pdf_filename
  end

  def DObject.raggruppa_per_folder(attachments)
    att=attachments.group_by {|a| a.folder}
    folders=[]
    att.keys.sort.each do |k|
      folder_title = k.nil? ? 'Attachments' : k.capitalize
      a=att[k]
      atc=a.sort {|x,y| x.position<=>y.position}
      dob=[]
      atc.each do |x|
        dob << x.d_object
      end
      folder_content=dob
      folders << [folder_title,folder_content]
    end
    folders
  end

  def DObject.fs_scan(folder,fdout=nil)
    digital_objects_dirscan(File.join(digital_objects_mount_point, folder), fdout)
  end

  def DObject.includes_metadata_tags?(filepath)
    return false if filepath.blank?
    pn=Pathname.new(filepath)
    pn.split.each do |f|
      f.to_s.split('#').each do |e|
        tag,data=e.split('_')
        return true if FILENAME_METADATA_TAGS.include?(tag.to_sym) and !data.blank?
      end
    end
    false
  end

end
