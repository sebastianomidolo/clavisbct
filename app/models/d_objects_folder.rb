# coding: utf-8
include DigitalObjects

class DObjectsFolder < ActiveRecord::Base
  attr_accessible :x_mid, :x_ti, :x_au, :x_an, :x_pp, :x_uid, :x_sc, :x_dc
  after_save :set_clavis_manifestation_attachments
  has_many :d_objects, order:'lower(name)'

  def filename
    self.name
  end

  def folder_content(params={})
    page = params[:page].blank? ? 1 : params[:page].to_i
    per_page = params[:per_page].blank? ? 50 : params[:per_page].to_i
    self.d_objects.paginate(page:page,per_page:per_page)
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
    sql=%Q{#{self.sql_conditions_for_user(user)} AND mode='rw'}
    res=self.connection.execute(sql).to_a.first
    res.nil? ? false : true
  end
  def readable_by=(user)
    self.set_permission(user,'ro')
  end
  def writable_by=(user)
    self.set_permission(user,'rw')
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

  def dir
    name=self.connection.quote_string(self.name)
    puts "name: #{name}"
    sql=%Q{with dirnames as (
      select string_to_array(substr(name, length('#{name}')+2), '/') as dirname
       from d_objects_folders where name like '#{name}/%'
      )
       select distinct dirname[1] from dirnames order by dirname[1]}
    res=self.connection.execute(sql).to_a
    return res
    res.each do |r|
      name=File.join(self.name,r['dirname'])
      f=DObjectsFolder.find_by_name(name)
      if f.nil?
        puts "NON trovato: #{name}"
        DObjectsFolder.makedir(name)
      end
    end
    res
  end

  def d_object_cover_image
    return nil if self.cover_image.blank? or !DObject.exists?(self.cover_image)
    DObject.find(self.cover_image)
  end
  
  def to_pdf(params={})
    d_objects=self.folder_content(params).collect do |o|
      mtype=o.mime_type.blank? ? '' : o.mime_type.split(';').first
      o if ['image/jpeg', 'image/tiff', 'image/png', 'application/pdf'].include?(mtype)
    end
    d_objects.compact!
    prm = params[:nologo].blank? ? {} : {nologo:true}
    DObject.to_pdf(d_objects,"/home/seb/nome_provvisorio.pdf", prm)
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

  def set_clavis_manifestation_attachments
    f_mid=self.x_mid
    # Se esiste una manifestation_id a livello di folder, questa viene usata per gli oggetti
    # contenuti nel folder, a meno che i singoli oggetti non abbiano una propria manifestation_id
    position=1
    sql=[]
    prec_manifestation_id=0
    self.d_objects.each do |o|
      # if (f_mid==0 and (o.x_mid==0 or o.x_mid.blank?)) or (o.x_mid==0 and (f_mid==0 or f_mid.blank?))
      sql << "DELETE FROM public.attachments WHERE attachable_type='ClavisManifestation' AND d_object_id=#{o.id};"
      if !(f_mid.blank? and o.x_mid.blank?)
        manifestation_id=o.x_mid.blank? ? f_mid : o.x_mid
        position=1 if manifestation_id!=prec_manifestation_id
        prec_manifestation_id=manifestation_id
        sql << "INSERT INTO public.attachments (attachable_type, attachable_id, d_object_id, position) VALUES('ClavisManifestation', #{manifestation_id}, #{o.id}, #{position});"
        position += 1
      end
    end
    DObjectsFolder.connection.execute(sql.join("\n"))
    nil
  end

  def DObjectsFolder.makedir(dirname)
    folder=DObjectsFolder.find_or_create_by_name(dirname)
    folder.write_tags_from_filename
    FileUtils.mkdir_p(folder.filename_with_path)
    folder
  end

end
