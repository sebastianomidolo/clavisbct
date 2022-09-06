# coding: utf-8
include DigitalObjects

class DObjectsFolder < ActiveRecord::Base
  attr_accessible :readme, :x_mid, :x_item_id, :x_ti, :x_au, :x_an, :x_pp, :x_uid, :x_sc, :x_dc, :basename, :name, :access_right_id
  after_save :set_clavis_manifestation_attachments, :derived_symlinks, :set_d_objects_access_right_id
  # after_save :derived_symlinks
  before_save :check_filesystem
  before_destroy :reset_sequence
  # has_many :d_objects, order:'lower(name)'
  has_many :d_objects, order:'naturalsort(lower(name))'
  has_one :talking_book
  belongs_to :access_right
  before_destroy do |record|
    # puts "record con id #{record.id} - cancellare file #{record.filename_with_path}"
    FileUtils.rmdir record.filename_with_path, :verbose => false
  end

  def filename
    self.name
  end

  def basename
    File.basename(self.name)
  end

  def delete_contents(user, d_objects_ids=nil)
    # puts "Cancello il contenuto del folder #{self.name}"
    ids=self.d_objects.collect{|x| x.id if x.writable_by?(user)}.compact
    if d_objects_ids.nil?
      # puts "cancello tutti i files contenuti in #{self.name}"
      self.delete_contents(user, ids)
    else
      # puts "cancello gli ids: #{d_objects_ids.inspect}"
      # Escludo eventuali ids non appartenenti ai d_objects del folder (self)
      d_objects_ids.reject! {|e| !ids.include? e}
      d_objects_ids.compact!
      # puts "DOPO il filtro, ids: #{d_objects_ids.inspect}"
      d_objects_ids.each do |o|
        # puts "Cancello #{o}"
        DObject.find(o).destroy
      end
    end
  end

  def basename=(newname)
    newname.strip!
    return if self.basename==newname or newname.blank?
    raise "Non è possibile modificare il nome della directory radice '#{}'" if File.dirname(self.name)=='.'
    self.name=File.join(File.dirname(self.name), newname)
  end

  def check_filesystem
    return if !self.changed?
    old,new=self.changes['name']
    return if old.nil?
    d_old = File.join(self.digital_objects_mount_point,old)
    d_new = File.join(self.digital_objects_mount_point,new)
    raise "Directory '#{d_new}' esistente, non posso rinominare #{d_old}" if Dir.exist?(d_new)
    FileUtils.mv(d_old, d_new)
    # Aggiorno eventuale cache:
    if File.exists?(File.join(self.digital_objects_cache, old))
      FileUtils.mv(File.join(self.digital_objects_cache, old), File.join(self.digital_objects_cache, new))
    end
    # Ora aggiorno sul db le eventuali "sottocartelle"
    DObjectsFolder.update_subfolders(old, new)
  end

  def reset_sequence
    sql="SELECT setval('public.d_objects_folders_id_seq', (select max(id) FROM public.d_objects_folders)+1)"
    self.connection.execute(sql)
  end

  def folder_content(params={})
    page = params[:page].blank? ? 1 : params[:page].to_i
    per_page = params[:per_page].blank? ? 50 : params[:per_page].to_i
    self.d_objects.paginate(page:page,per_page:per_page)
  end

  # Alternativa: usare gfx_size
  def contains_images?
    self.gfx_size==0 ? false : true
  end

  def cover_image=(t) self.edit_tags(cover_image:t.to_s) end
  def cover_image() self.xmltag(:cover_image) end

  def set_cover_image
    self.tags='<r></r>' if self.tags.nil?
    return if !self.cover_image.blank?
    puts name
    self.d_objects.each do |o|
      next if o.mime_type.blank?
      if ['image/jpeg','image/tiff','image/png','application/pdf'].include?(o.mime_type.split(';').first)
        self.cover_image=o.id
        self.save
        return
      else
        puts o.mime_type
      end
    end
  end

  def sql_conditions_for_user(user)
    user_id=user.class==Fixnum ? user : user.id
    %Q{SELECT true FROM d_objects_folders_users fu JOIN d_objects_folders f
       ON( (fu.d_objects_folder_id=f.id OR f.name || '/' LIKE fu.pattern || '%') AND fu.user_id=#{user_id})
       WHERE f.id=#{self.id}}
  end

  def readable_by?(user)
    sql=self.sql_conditions_for_user(user)
    res=self.connection.execute(sql).to_a.first
    res.nil? ? false : true
  end

  def writable_by?(user)
    sql=%Q{#{self.sql_conditions_for_user(user)} AND mode in('rw','rd')}
    res=self.connection.execute(sql).to_a.first
    res.nil? ? false : true
  end

  def deletable_by?(user)
    sql=%Q{#{self.sql_conditions_for_user(user)} AND mode='rd'}
    res=self.connection.execute(sql).to_a.first
    res.nil? ? false : true
  end

  def readable_by=(user)
    self.set_permission(user,'ro')
  end
  def writable_by=(user)
    self.set_permission(user,'rw')
  end
  def deletable_by=(user)
    self.set_permission(user,'rd')
  end

  def disable_user(user)
    user_id=user.class==Fixnum ? user : user.id
    sql=%Q{DELETE FROM d_objects_folders_users WHERE user_id=#{user_id} AND d_objects_folder_id=#{self.id}}
    self.connection.execute(sql)    
  end
  def set_permission(user,mode)
    user_id=user.class==Fixnum ? user : user.id
    if self.readable_by?(user)
      sql=%Q{UPDATE d_objects_folders_users SET mode='#{mode}' WHERE user_id=#{user_id} AND d_objects_folder_id=#{self.id} AND mode!='#{mode}'}
    else
      sql=%Q{INSERT INTO d_objects_folders_users (user_id,d_objects_folder_id,mode) VALUES(#{user_id},#{self.id},'#{mode}')}
    end
    self.connection.execute(sql)
  end

  def makedir(foldername)
    foldername.strip!
    foldername.gsub!(/[^-\p{Alnum}]/, ' ')
    return self if foldername.blank?
    DObjectsFolder.makedir(File.join(self.name,foldername))
  end

  def filename_with_path
    File.join(self.digital_objects_mount_point,self.name)
  end

  def parent
    p=self.split_path.last
    return nil if p.nil?
    DObjectsFolder.find(p[1])
  end

  def split_path
    res=[]
    path=self.name.split('/')
    while path!=[]
      s=path.join('/')
      f=DObjectsFolder.find_by_name(s)
      parte=path.pop
      if f.nil?
        # puts "dovrei creare: #{s}"
        f=DObjectsFolder.makedir(s)
      end
      next if f.nil? or f.id==self.id
      res << [parte,f.id]
    end
    res.reverse
  end

  def dir(sort='asc',condition=nil,limit=nil)
    name=self.connection.quote_string(self.name)
    limit = limit.nil? ? '' : "LIMIT #{limit}"
    cond = condition.nil? ? '' : " AND #{condition}"
    # order by regexp_replace(name, E'\\D','','g')
    sql=%Q{select * from d_objects_folders where (name like '#{name}/%') and\n not (name ~ '#{name}/(.*)(/)') #{cond}
             order by naturalsort(name) #{sort} #{limit};}
    fd=File.open('/home/seb/test.sql', 'a')
    fd.write("-- dir(sort=#{sort}, condition=#{condition},limit=#{limit})\n#{sql};\n")
    fd.close
    # Alternativa (bisogna calcolare slash_count
    # slash_count = ?
    #      select * from d_objects_folders where array_length(string_to_array(name, '/'),1)=#{slash_count} and name like '#{name}/%' order by name;
    DObjectsFolder.find_by_sql(sql)
  end

  def d_object_cover_image
    return nil if self.cover_image.blank? or !DObject.exists?(self.cover_image)
    DObject.find(self.cover_image)
  end

  def free_pdf_filename
    return nil if self.x_mid.blank?
    ClavisManifestation.free_pdf_filename(self.x_mid)
  end

  def derived_pdf_filename(seqnum=nil)
    config = Rails.configuration.database_configuration
    if seqnum.nil?
      "#{File.join(config[Rails.env]["digital_objects_cache"], 'derived', self.id.to_s)}.pdf"
    else
      "#{File.join(config[Rails.env]["digital_objects_cache"], 'derived', self.id.to_s + '-' + seqnum.to_s)}.pdf"
    end
  end

  def pdf_url
    self.access_right_id = 1 if self.access_right_id.nil?
    if self.access_right_id==0 and self.free_pdf_filename
      publ=true
    else
      publ=false
    end
    url=nil
    fname=self.derived_pdf_filename
    if fname and File.readable?(fname)
      if publ==true
        url="getpdf/#{File.basename(self.free_pdf_filename)}"
      else
        url="d_objects_folders/#{self.id}/derived.pdf"
      end
    end
    url
  end

  def restricted_pdf_filename
    config = Rails.configuration.database_configuration
    "#{File.join(config[Rails.env]["digital_objects_cache"], 'restricted', self.id.to_s)}.pdf"
  end

  def gfx_objects
    objs=self.d_objects.collect do |o|
      mtype=o.mime_type.blank? ? '' : o.mime_type.split(';').first
      o if ['image/jpeg', 'image/tiff', 'image/png', 'application/pdf'].include?(mtype)
    end
    objs.compact
  end

  def gfx_size
    size=0
    self.gfx_objects.each {|o| size+=o.bfilesize}
    size
  end

  def automake_pdf(max_per_page=200)
    puts "automake_pdf: max_per_page #{max_per_page}"
  end

  def to_pdf(params={})
    params=self.pdf_params if params.size==0
    h=Hash.new
    params.each do |k,v|
      h[k.to_sym]=v if k.class==String
    end
    pages=self.gfx_objects
    puts pages.size
    puts "pdf_params: #{self.pdf_params}"
    page_ranges=self.pdf_params['pages']
    if !page_ranges.blank?
      puts "page_ranges: #{page_ranges}"
      cnt=0
      images=self.gfx_objects
      page_ranges.split(',').each do |p|
        cnt+=1
        from,to=p.split('-')
        from = from.to_i - 1
        to = to.to_i - 1
        puts "p: #{p} - from: #{from} ; to: #{to} - #{self.derived_pdf_filename(cnt)}"
        DObject.to_pdf(images[from..to],self.derived_pdf_filename(cnt), params.merge(h))
      end
    else
      DObject.to_pdf(self.gfx_objects,self.derived_pdf_filename, params.merge(h))
    end
  end

  def to_pdftest(params={})
    DObject.to_pdftest(self.gfx_objects)
  end

  def pdf_params=(t) self.edit_tags(pdf_params:t) end
  def pdf_params()
    res=self.xmltag('pdf_params')
    res.nil? ? '' : res
  end

  def x_mid=(t) self.edit_tags(mid:t) end
  def x_mid() self.xmltag('mid') end

  def x_item_id=(t) self.edit_tags(item_id:t) end
  def x_item_id() self.xmltag('item_id') end

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

  def pdf_disabled=(t) self.edit_tags(pdf_disabled:t) end
  def pdf_disabled() self.xmltag('pdf_disabled') end

  def attachment_category=(t) self.edit_tags(attachment_category:t) end
  def attachment_category() self.xmltag('attachment_category') end

  def readme=(t) self.edit_tags(readme:t) end
  def readme() self.xmltag('readme') end

  def set_clavis_manifestation_attachments
    f_mid=self.x_mid
    # Se esiste una manifestation_id a livello di folder, questa viene usata per gli oggetti
    # contenuti nel folder, a meno che i singoli oggetti non abbiano una propria manifestation_id
    position=1
    sql=[]
    prec_manifestation_id=0
    ac = self.attachment_category
    attachment_category_id = ac.blank? ? 'NULL' : self.connection.quote(ac)
    self.d_objects.each do |o|
      # if (f_mid==0 and (o.x_mid==0 or o.x_mid.blank?)) or (o.x_mid==0 and (f_mid==0 or f_mid.blank?))
      # sql << "DELETE FROM public.attachments WHERE attachable_type='ClavisManifestation' AND d_object_id=#{o.id};"
      if f_mid.blank?
        sql << "DELETE FROM public.attachments WHERE attachable_type='ClavisManifestation' AND d_object_id=#{o.id};"
      end
      if !(f_mid.blank? and o.x_mid.blank?)
        manifestation_id=o.x_mid.blank? ? f_mid : o.x_mid
        position=1 if manifestation_id!=prec_manifestation_id
        prec_manifestation_id=manifestation_id
        sql << %Q{INSERT INTO public.attachments (attachable_type, attachable_id, d_object_id, position, attachment_category_id)
                    VALUES('ClavisManifestation', #{manifestation_id}, #{o.id}, #{position}, #{attachment_category_id})
                      ON CONFLICT (attachable_type, attachable_id, d_object_id) DO
                       UPDATE set attachment_category_id = #{attachment_category_id};}
        position += 1
      end
    end
    if f_mid.blank?
      puts "Cancello entry in manifestations_d_objects_folders per folder #{self.id}"
      sql << "DELETE FROM manifestations_d_objects_folders WHERE d_objects_folder_id = #{self.id};"
    else
      sql << "INSERT INTO manifestations_d_objects_folders (d_objects_folder_id, manifestation_id)
                   VALUES (#{self.id}, #{f_mid}) on conflict(d_objects_folder_id) DO NOTHING;"
    end
    # puts sql.join("\n")
    DObjectsFolder.connection.execute(sql.join("\n"))
    nil
  end

  def browse_object(cmd)
    return nil if self.parent.nil?
    fname=self.connection.quote(self.name)
    case cmd
    when 'prev'
      r=self.parent.dir('desc',"name < #{fname}",1).first
    when 'next'
      r=self.parent.dir('asc',"name > #{fname}",1).first
    when 'first'
      r=self.parent.dir('asc',nil,1).first
    when 'last'
      r=self.parent.dir('desc',nil,1).first
    else
      raise "browse_object('prev'|'next'|'first'|'last')"
    end
    return nil if r.nil?
    # puts "self.id = #{self.id} - r.id = #{r.id}"
    r
  end

  def derived_symlinks
    return if self.changes[:access_right_id].nil?
    old,new=self.changes[:access_right_id]
    puts "qui: old = #{old}"
    puts "qui: new = #{new}"
    puts "free_pdf_filename: #{self.free_pdf_filename}"
    # 0 - Risorsa libera
    # 3 - Risorsa con accesso ristretto agli utenti autenticati con credenziali DiscoveryNG
    case old
    when 0
      puts "Era risorsa libera"
      FileUtils.rm(self.free_pdf_filename, force:true) if self.free_pdf_filename
    when 3
      FileUtils.rm(self.restricted_pdf_filename, force:true)
    end
    case new
    when 0
      FileUtils.ln_s(self.derived_pdf_filename,self.free_pdf_filename,force:true) if self.free_pdf_filename
    when 3
      puts "#{self.derived_pdf_filename} => #{self.restricted_pdf_filename}"
      FileUtils.ln_s(self.derived_pdf_filename,self.restricted_pdf_filename,force:true)
    end
  end

  def set_d_objects_access_right_id(rights_id=nil)
    if rights_id.nil?
      val = self.access_right_id.nil? ? 'NULL' : self.access_right_id
    else
      val = rights_id
    end
    msg = "Imposto diritti a #{val} su folder #{self.id} (#{self.name})"
    sql = []
    if !rights_id.nil?
      self.connection.execute("-- #{msg}\nUPDATE d_objects_folders SET access_right_id = #{val} WHERE id=#{self.id};")
    end
    sql << %Q{-- #{msg}\nUPDATE d_objects SET access_right_id = #{val} WHERE d_objects_folder_id=#{self.id};}
    self.dir.each do |f|
      sql << f.set_d_objects_access_right_id(val)
    end
    if rights_id.nil?
      puts "Eseguo sql (size: #{sql.size}) - folder #{self.id} (#{self.name})"
      self.connection.execute(sql.flatten.join("\n"))
    else
    end
    sql
  end
  
  def references(include_d_objects=false)
    if include_d_objects
      select="a.*,o.*"
    else
      select="a.*"
    end
    sql=%Q{select #{select} from d_objects o join attachments a on (a.d_object_id=o.id) where o.d_objects_folder_id=#{self.id}
       AND a.position=1 order by o.id desc}
    puts sql
    a=Attachment.find_by_sql(sql)
    if a==[]
      sql=%Q{select a.* from d_objects o join attachments a on (a.d_object_id=o.id) where o.d_objects_folder_id=#{self.id} limit 1}
      a=Attachment.find_by_sql(sql)
    end
    a
  end

  def files_caricati_oggi
    self.connection.execute("select count(*) from d_objects where d_objects_folder_id=#{self.id} and f_ctime >= now()::date + interval '1h'").to_a.first['count'].to_i
  end

  def manifestation_ids_duplicati
    self.connection.execute("select attachable_type,attachable_id,count(*) from attachments a join d_objects o on(o.id=a.d_object_id) where o.d_objects_folder_id=#{self.id} group by attachable_type,attachable_id having count(*)>1").to_a
  end

  def download
    retval={}
    prefix='clavisbct'
    http_prefix='https://bctwww.comperio.it/static'
    destdir='/home/storage/preesistente/static'
    filepath_prefix="#{prefix}/#{self.name}"
    pattern_name = filepath_prefix.gsub('/','_')
    filenames    = "#{destdir}/#{pattern_name}_filelist.txt"
    tarfile      = "#{destdir}/#{pattern_name}.tar"
    sql_inserts  = "#{destdir}/#{pattern_name}_sql_inserts.sql"

    cmd = %Q{tar cvf #{tarfile} -C #{self.filename_with_path} --files-from=#{filenames}}
    puts "prefix:            #{prefix}"
    puts "destdir:           #{destdir}"
    puts "filepath_prefix:   #{filepath_prefix}"
    puts "pattern_name:      #{pattern_name}"
    puts "tarfile:           #{tarfile}"
    puts "filenames:         #{filenames}"
    puts "sql_inserts:       #{sql_inserts}"
    puts "cmd:               #{cmd}"
    retval[:tarfile]="#{http_prefix}/#{pattern_name}.tar"
    retval[:sql_inserts]="#{http_prefix}/#{pattern_name}_sql_inserts.sql"
    fd=File.open(filenames, 'w')
    fdsql=File.open(sql_inserts, 'w')
    fdsql.write("-- File: #{tarfile};\n");
    fdsql.write("delete from attachment where file_path like '#{filepath_prefix}/%';\n");
    cnt=0
    nocnt=0
    self.references(true).each do |r|
      if r.access_right_id!='0'
        puts "controllare access_right_id per d_object #{r.d_object_id} su manifestation #{r.attachable_id}"
        nocnt += 1
        next
      end
      cnt += 1
      filename_in_archive = "file_#{format('%08d',r.attachable_id)}.jpg"
      filepath = ActiveRecord::Base.connection.quote("#{filepath_prefix}/#{filename_in_archive}")
      filename = ActiveRecord::Base.connection.quote(r.name)
      fdsql.write(%Q{INSERT INTO attachment (attachment_type,object_id,object_type,mime_type,
              file_size,file_path,file_label,license,file_description,
              file_name,date_created,date_updated,created_by,modified_by)
        VALUES ('E',#{r.attachable_id},'Manifestation','#{r.mime_type.split(';').first}',
                #{r.bfilesize},#{filepath},NULL,'A',NULL,
                '#{filename_in_archive}','#{r.f_ctime}','#{r.f_mtime}',1,1);
        UPDATE turbomarc_cache SET dirty=1 WHERE manifestation_id=#{r.attachable_id};\n})
      fd.write("--transform 's|.*|#{filename_in_archive}|;s,^,#{filepath_prefix}/,'\n#{r.name}\n");
      # puts DObject.find(r.object_id).name
    end
    if nocnt==0
      fdsql.write("-- Caricate tutte le immagini presenti nella cartella (#{cnt})\n");
    else
      fdsql.write("-- #{nocnt} immagini non caricate, diritti d'accesso non specificati;\n");
    end
    fdsql.close
    fd.close
    cmd = %Q{tar cf #{tarfile} -C #{self.filename_with_path} --files-from=#{filenames}}
    Kernel.system(cmd)
    # cmd = %Q{tar uvf #{tarfile} --transform 's,^,clavisbct/,' -C #{File.dirname(sql_inserts)} #{File.basename(sql_inserts)}}
    # cmd = %Q{tar uvf #{tarfile} --transform 's,^,#{filepath_prefix}/,' -C #{File.dirname(sql_inserts)} #{File.basename(sql_inserts)}}
    # Kernel.system(cmd)
    retval
  end

  # Non usata, è una prova del 18 dicembre 2019
  def DObjectsFolder.estrai_collocazione(start,string)
    r=Regexp.new "#{start}(\\d+)(\\D*)"
    m=string.match r
    m.nil? ? nil : m[1]
  end
  
  def DObjectsFolder.makedir(dirname)
    folder=DObjectsFolder.find_or_create_by_name(dirname)
    folder.write_tags_from_filename
    FileUtils.mkdir_p(folder.filename_with_path)
    folder
  end

  def DObjectsFolder.update_subfolders(old, new)
    old=self.connection.quote(old)
    new=self.connection.quote(new)
    sql=%Q{UPDATE #{self.table_name} set name = regexp_replace(name, #{old}, #{new}) WHERE name ~ #{old}}
    self.connection.execute(sql)
  end

  def DObjectsFolder.import_folders(sourcedir, destdir)
    puts "Importazione oggetti digitali da #{sourcedir} a #{destdir}"
    dirlist=Hash.new
    Dir.glob("#{sourcedir}/**/*").each do |dirname|
      next if File.file?(dirname)
      slot=File.basename(dirname)
      # puts "Entro in #{slot}"
      dir_ok = false
      Dir.glob("#{dirname}/*").each do |fname|
        dir_ok=true if File.file?(fname)
      end
      if dir_ok
        dirname[dirname.index(destdir)..-1]
        folder = DObjectsFolder.new(name:dirname[dirname.index(destdir)..-1])
        next if !File.exists?(folder.filename_with_path)
        puts "Scansione contenuti di #{folder.name}"
        DObject.fs_scan(folder.name)
        s=folder.name
        while true
          i=s.rindex('/')
          break if i.nil?
          s=s[0..i-1]
          dirlist[s]=true
        end
      end
    end
    # Verifico che esistano sul DB le cartelle parents di quelle indicizzate nel loop precedente
    dirlist.keys.each do |f|
      dbf=DObjectsFolder.find_by_name(f)
      next if !dbf.nil?
      puts "creo istanza di DObjectsFolder per #{f}"
      folder = DObjectsFolder.create(name:f)
      folder.write_tags_from_filename
    end
    nil
  end

end
