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

end
