# coding: utf-8
require 'RMagick'

include DigitalObjects
require 'rexml/document'
require 'mp3info'
require 'will_paginate/array'

class DObject < ActiveRecord::Base
  attr_accessible :filename, :access_right_id, :mime_type, :tags,
                  :x_mid, :x_ti, :x_au, :x_an, :x_pp, :x_uid, :x_sc, :x_dc
  has_many :references, :class_name=>'Attachment', :foreign_key=>'d_object_id'
  belongs_to :access_right
  belongs_to :d_objects_folder
  before_save :check_filesystem
  after_save :set_clavis_manifestation_attachment
  after_destroy do |record|
    # puts "record con id #{record.id} - cancellare file #{record.filename_with_path}"
    File.delete record.filename_with_path if File.exists?(record.filename_with_path)
  end

  def check_filesystem
    # Commentato il 23 agosto 2016 perché in alcune situazioni dà errore
    # (per esempio tentando di salvare un record da http://clavisbct.comperio.it/bio_iconografico_cards/49689045/edit)
    return if (self.filename =~ /^bm::/)==0
    self.digital_object_read_metadata
  end

  def read_metadata_da_cancellare
    self.digital_object_read_metadata
    puts self.mime_type
    puts "filesize: #{bfilesize}"
    self.save if self.changed?
  end

  def reassign_id(from,to)
    sql=%Q{with ids as (select id from generate_series(#{from}, #{to}) as id)
          select id from ids left join d_objects o using(id) where o.id is null limit 1}
    new_id=self.connection.execute(sql).first
    return nil if new_id.nil?
    new_id=self.connection.execute(sql).first['id'].to_i
    sql=%Q{UPDATE d_objects SET id=#{new_id} WHERE id=#{self.id}}
    self.connection.execute(sql)
    self.id=new_id
  end

  def access_right_to_label
    self.access_right_id.nil? ? 'diritti non specificati' : self.access_right.description
  end

  def save_new_record(params,creator)
    uploaded_io = params[:filename]
    random_fname="#{SecureRandom.urlsafe_base64}#{uploaded_io.original_filename}"
    mp=self.digital_objects_mount_point
    full_filename=File.join(mp, 'upload', random_fname)
    # Scrivo il file in posizione provvisoria
    File.open(full_filename, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    self.filename=full_filename.sub(mp,'')
    # Acquisisco i metadati del file appena scritto
    self.digital_object_read_metadata
    # Determino xmltags iniziali
    self.tags={original_filename:uploaded_io.original_filename,created_by:creator.id.to_s}.to_xml(root:'r',:skip_instruct => true, :indent => 0)

    # Devo salvare due volte il file, perché la prima volta ottengo l'id del record
    # che mi serve per determinare il nome canonico del file
    self.save
    # A questo punto si prospettano due scenari distinti:
    #   1. non è presente il parametro d_objects_folder_id
    #   2. è presente il parametro d_objects_folder_id
    # Nel primo caso, acquisisco il nome canonico del file determinato dai metadati appena creati e
    # sposto il file nella posizione definitiva, in accordo al suo nome canonico
    # Nel secondo caso, il file deve essere spostato nel folder corrispondente,
    # previa verifica dell'eventuale esistenza in quella posizione di un file omonimo,
    # che non dovrà essere sovrascritto
    if params[:d_objects_folder_id].blank?
      self.filename=self.canonical_filename
      sfn=File.join(mp, self.filename)
      FileUtils.mkdir_p(File.dirname(sfn))
    else
      folder=DObjectsFolder.find(params[:d_objects_folder_id])
      self.d_objects_folder_id=folder.id
      self.name=uploaded_io.original_filename
      sfn=File.join(mp, folder.name, self.name)
      fd=File.open("/tmp/debug.log", "w")
      fd.write(sfn)
      fd.close
      if File.exists?(sfn)
        sfn=File.join(mp, folder.name, random_fname)
        self.name=random_fname
      end
    end
    FileUtils.mv(full_filename, sfn)

    # Salvo il record per la seconda volta
    self.write_tags_from_filename
    self.save if self.changed?
    # Se è un file zip estraggo i files
    self.unpack_zip_archive
    # self.clavis_manifestation_attachments_set
    self
  end

  # Funziona per i files zip caricati interattivamente
  def clavis_manifestation_attachments_set
    return if self.x_mid.blank? or self.mime_type.split(';').first!='application/zip'
    pattern=File.join(File.dirname(self.filename),File.basename(self.filename, File.extname(self.filename)))
    pattern=self.connection.quote_string(pattern)
    sql=%Q{INSERT INTO public.attachments
       (d_object_id,attachable_id,attachable_type,attachment_category_id,position)
       (SELECT id,#{self.x_mid},'ClavisManifestation','C',row_number() OVER (ORDER BY lower(filename_old_style))
            FROM d_objects WHERE filename LIKE '#{pattern}/%')}
    self.connection.execute(sql)
  end

  def set_clavis_manifestation_attachment
    sql=[]
    o=self
    sql << "DELETE FROM public.attachments WHERE attachable_type='ClavisManifestation' AND d_object_id=#{o.id};"
    if !o.x_mid.blank?
      manifestation_id=o.x_mid
      position=1
      sql << "INSERT INTO public.attachments (attachable_type, attachable_id, d_object_id, position) VALUES('ClavisManifestation', #{manifestation_id}, #{o.id}, #{position});"
    end
    DObject.connection.execute(sql.join("\n"))
    nil
  end



  
  def file_extension
    self.mime_type.split(';').first.split('/').last
  end

  def canonical_filename
    fname=self.original_filename.blank? ? "#{self.id.to_s}.#{self.file_extension}" : "#{self.id}_#{self.original_filename}"
    "#{File.join('uploaded', self.f_mtime.year.to_s, self.created_by, fname)}"
  end

  def unpack_zip_archive
    return false if self.mime_type.split(';').first!='application/zip'
    destdir=File.join(File.dirname(self.filename_with_path),File.basename(self.filename, File.extname(self.filename)))
    FileUtils.mkdir_p(destdir)
    Zip::File.open(self.filename_with_path) do |zip_file|
      zip_file.each do |entry|
        next if entry.directory?
        dest_file=File.join(destdir, File.basename(entry.name))
        next if File.exist?(dest_file)
        entry.extract(dest_file)
      end
    end
    DObject.fs_scan(destdir.sub(self.digital_objects_mount_point,''))
    true
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

  def x_mid=(t) self.edit_tags(mid:t) end
  def x_mid() self.xmltag('mid') end

  def x_ti=(t) self.edit_tags(ti:t) end
  def x_ti() self.xmltag('ti') end
  
  def x_au=(t) self.edit_tags(au:t) end
  def x_au() self.xmltag('au') end

  def x_an=(t) self.edit_tags(an:t) end
  def x_an() self.xmltag('an') end

  def x_pp=(t) self.edit_tags(pp:t) end
  def x_pp() self.xmltag('pp') end

  def x_uid=(t) self.edit_tags(uid:t) end
  def x_uid() self.xmltag('uid') end

  def x_sc=(t) self.edit_tags(sc:t) end
  def x_sc() self.xmltag('sc') end

  def x_dc=(t) self.edit_tags(dc:t) end
  def x_dc() self.xmltag('dc') end

  def created_by() self.xmltag('created-by') end
  def original_filename() self.xmltag('original-filename') end

  def get_pdfimage(n=1)
    return nil if (/^application\/pdf/ =~ self.mime_type).nil?
    self.pdf_to_jpeg if self.pdf_count_pages==0
    f=self.pdf_filename_for_jpeg(n)
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

  def pdf_count_pages
    return 0 if self.mime_type!='application/pdf; charset=binary'
    s=Dir.glob("#{self.pdf_filename_for_jpeg}*").size
    self.pdf_to_jpeg if s==0
    Dir.glob("#{self.pdf_filename_for_jpeg}*").size
  end

  def pdf_filename_for_jpeg(page_number=nil)
    if page_number.nil?
      "#{self.pdf_rootname}-"
    else
      "#{self.pdf_rootname}-#{format('%03d',page_number)}.jpeg"
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
      jpegfile=self.pdf_filename_for_jpeg(cnt)
      cnt+=1
      i.write(jpegfile)
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

  def write_fulltext_from_pdf
    ft=self.get_fulltext_from_pdf
    return nil if ft.blank?
    self.tags=ft.to_xml(:root=>:r,:skip_instruct=>true,:indent=>0)
    self.save if self.changed?
  end

  def filename
    File.join(self.d_objects_folder.name, self.name)
  end

  def filename=(pathname)
    orig_folder_id=self.d_objects_folder_id
    f=DObjectsFolder.find_or_create_by_name(File.dirname(pathname))
    self.d_objects_folder_id=f.id
    self.name=File.basename(pathname)
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

  def is_cover_image?
    self.id===self.d_objects_folder.cover_image.to_i
  end

  def get_tracklist
    return [] if self.tags.nil?
    doc = REXML::Document.new(self.tags)
    # return [] if doc.root.name!='tracklist'

    elements = doc.root.name=='tracklist' ? doc.root.elements : XPath.first(doc, "//tracklist")
    return [] if elements.nil?
    res=[]
    elements.each do |e|
      cnt=e.attributes['position'].blank? ? nil : e.attributes['position'].to_i
      res << {e.name => e.text, attributes: e.attributes, :audioclip=>self.audioclip_exists?(cnt)}
    end
    res
  end

  def clavis_manifestation_id
    self.references.each do |r|
      return r.attachable_id if r.attachable_type=='ClavisManifestation'
    end
    nil
  end

  # da eliminare
  #def folder_content(params={})
  #  page = params[:page].blank? ? 1 : params[:page].to_i
  #  per_page = params[:per_page].blank? ? 50 : params[:per_page].to_i
  #  self.d_objects_folder.d_objects.paginate(page:page,per_page:per_page)
  #end

  def d_objects_folder_sostituita_da_belongs_to
    sql=%Q{SELECT * from d_objects_folders f JOIN d_objects_d_objects_folders d
             ON d.d_objects_folder_id=f.id AND d.d_object_id=#{self.id}}
    DObjectsFolder.find_by_sql(sql).first
  end

  # Usata da ClavisManifestation#attachments_generate_pdf
  def DObject.to_pdf(ids,pdf_filename,params={})
    # return true if File.exists?(pdf_filename)
    if params[:nologo].blank?
      logo = Magick::Image.read("/home/storage/preesistente/testzone/bctcopyr.gif").first
    end
    iList =  Magick::ImageList.new
    ids.each do |o|
      # puts o.filename
      img=Magick::Image.read(o.filename_with_path).first
      if params[:nologo].blank?
        img.resize_to_fit!(2000)
        img=img.watermark(logo,0.1,0.5,Magick::NorthGravity,0,0)
        img=img.watermark(logo,0.9,0.5,Magick::SouthGravity,0,0)
      end
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

  def DObject.find_or_create_by_filename(fname)
    f=DObjectsFolder.find_or_create_by_name(File.dirname(fname))
    puts "f: #{f.inspect}"
    return nil if f.nil?
    DObject.find_or_create_by_name_and_d_objects_folder_id(File.basename(fname),f.id)
  end

end
