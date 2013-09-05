# lastmod 20 febbraio 2013

class ClavisManifestation < ActiveRecord::Base
  # attr_accessible :title, :body
  self.table_name = 'clavis.manifestation'
  self.primary_key = 'manifestation_id'


  # self.per_page = 10

  has_many :clavis_items, :foreign_key=>'manifestation_id'
  has_many :clavis_issues, :foreign_key=>'manifestation_id'

  has_many :attachments, :as => :attachable

  def d_objects_set_access_rights(access_right)
    ActiveRecord::Base.transaction do
      self.d_objects.each do |o|
        o.access_right=access_right
        o.save if o.changed?
      end
    end
  end

  def d_objects(folder=nil,conditions='')
    conditions = "AND #{conditions}" if !conditions.blank?
    if folder.blank?
      extra=''
      order='a.position'
    else
      extra="AND a.folder=#{self.connection.quote(folder)}"
      order='lower(folder),a.position'
    end
    sql=%Q{SELECT o.* FROM clavis.manifestation m JOIN public.attachments a
      ON(a.attachable_type='ClavisManifestation' AND a.attachable_id=m.manifestation_id)
      JOIN public.d_objects o ON(o.id=a.d_object_id)
      WHERE m.manifestation_id=#{self.id} #{extra}
      #{conditions}
      ORDER by #{order};}
    puts sql
    DObject.find_by_sql(sql)
  end

  def to_label
    self.title
  end

  def attachments_folders
    sql=%Q{SELECT DISTINCT folder,lower(folder) FROM clavis.manifestation m JOIN public.attachments a
      ON(a.attachable_type='ClavisManifestation' AND a.attachable_id=m.manifestation_id)
      WHERE m.manifestation_id=#{self.id} ORDER BY lower(folder);}
    # puts sql
    res=[]
    self.connection.execute(sql).each do |r|
      res << r['folder']
    end
    res
  end

  def attachments_pdf_filename(folder,counter,perfile,numfiles,total,frompage,topage)
    puts "counter: #{counter} - numfiles: #{numfiles}"
    zeros=numfiles.to_s.size
    counter=format("%0#{zeros}d", counter)
    folder="_#{folder}" if !folder.blank?
    fp=format("%0#{total.to_s.size}d", frompage)
    tp=format("%0#{total.to_s.size}d", topage)
    if numfiles==1
      extra="_p#{total}"
    else
      extra="_#{counter}_of_#{numfiles}"
      extra+="_p#{fp}-#{tp}_of_#{total}"
    end
    File.join(DObject.digital_objects_cache, "#{self.id}#{folder}#{extra}.pdf".gsub(' ','_'))
  end

  def attachments_generate_pdf(generate,perfile=50)
    fnames=[]
    self.attachments_folders.each do |folder|
      dobs=self.d_objects(folder, "mime_type ~* '^image'")
      numpages=dobs.size
      dobs=dobs.each_slice(perfile).to_a
      numfiles=dobs.size
      cnt=0
      pgcnt=1
      pgdone=1
      dobs.each do |ar|
        cnt+=1
        pgdone+=ar.size-1
        # puts "#{numpages} numpages (#{pgcnt}-#{pgdone}) in folder #{folder}"
        fname=attachments_pdf_filename(folder,cnt,perfile,numfiles,numpages,pgcnt,pgdone)
        puts fname
        pgdone+=1
        pgcnt=pgdone
        if File.exists?(fname)
          # puts "Esiste #{fname}"
        else
          # puts "Da creare #{fname}"
          DObject.to_pdf(ar, fname) if generate
        end
        fnames << fname
      end
    end
    fnames
  end

  def ultimi_fascicoli
    self.clavis_issues.all(:order=>'issue_id desc', :limit=>10)
  end

  def clavis_url(mode=:show)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    r=''
    if mode==:show
      r="#{host}/index.php?page=Catalog.Record&manifestationId=#{self.id}"
    end
    if mode==:edit
      r="#{host}/index.php?page=Catalog.EditRecord&manifestationId=#{self.id}"
    end
    if mode==:opac
      host=config[Rails.env]['clavis_host_dng']
      r="#{host}/opac/detail/view/sbct:catalog:#{self.id}"
    end
    r
  end

  def thebid
    self.bid.blank? ? 'nobid' : "#{self.bid_source}-#{self.bid}"
  end

end
