# -*- coding: utf-8 -*-
# lastmod 20 febbraio 2013

include DigitalObjects
include REXML

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
    sql=%Q{SELECT o.*,ar.description as access_rights_description,a.attachment_category_id
       FROM clavis.manifestation m JOIN public.attachments a
      ON(a.attachable_type='ClavisManifestation' AND a.attachable_id=m.manifestation_id)
      JOIN public.d_objects o ON(o.id=a.d_object_id)
      LEFT JOIN public.access_rights ar ON(ar.code=o.access_right_id)
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
    puts sql
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

  def attachments_zipfilename
    File.join(DigitalObjects.digital_objects_cache, "mid_#{self.id}.zip")
  end

  def attachments_zip
    require 'zip'
    basedir=DigitalObjects.digital_objects_mount_point
    zipfile_name = self.attachments_zipfilename
    File.delete(zipfile_name) if File.exists?(zipfile_name)
    puts zipfile_name
    readme_info = self.d_objects.collect do |o|
      o.access_rights_description
    end
    readme_info.uniq!
    tf = Tempfile.new("readme_zip",File.join(Rails.root.to_s, 'tmp'))
    readme_filename=tf.path
    fdout=File.open(readme_filename,'w')
    readme_info.each do |r|
      fdout.write("#{r}\n")
    end
    fdout.close

    folder_title=self.title.strip
    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      zipfile.add(File.join(folder_title, "LEGGIMI.txt"), readme_filename)
      Attachment.filelist(self.attachments).each do |folder|
        foldername,foldercontent=folder
        foldercontent.each do |filename|
          if foldername.blank?
            fname=File.basename(filename)
          else
            fname=File.join(foldername, File.basename(filename))
          end
          origfile = File.join(basedir,filename)
          fname=File.join(folder_title,fname)
          puts "fname: #{fname} completo #{origfile}"
          zipfile.add(fname, origfile)
        end
      end
    end
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

  def audioclips
    cm=self
    storage_dir=DigitalObjects.digital_objects_mount_point
    title=cm.title.strip
    d_objects=cm.d_objects
    clips=[]
    cnt=0
    d_objects.each do |o|
      next if o.attachment_category_id!='D'
      # creo audioclip della durata specificata (40 secondi, per esempio)
      clipfn=o.digital_object_create_audioclip(40)
      if !clipfn.nil?
        cnt+=1
        clip = DObject.new(filename: clipfn, access_right_id: 0, mime_type: 'audio/mpeg; charset=binary',
                           tags: "<r><title>Preascolto traccia #{cnt}</title></r>")
        clip.id=o.id
        clips << clip
      end
    end
    clips
  end

  def thebid
    self.bid.blank? ? 'nobid' : "#{self.bid_source}-#{self.bid}"
  end

  def reticolo
    sql=%Q{select
      lam.link_type,a.full_text as authority,lv.value_label as authtype,l.ill_code as library_code,
      ci.inventory_serie_id || '-' || ci.inventory_number as inventario,
      ci.section || '.' || ci.collocation as collocazione,
      lm.manifestation_id_up, trim(lm.link_sequence) as link_sequence
      from clavis.manifestation cm
       left join clavis.item ci ON(cm.manifestation_id=ci.manifestation_id
             AND ci.opac_visible='1'
             AND ci.item_status IN ('F','G','K','V'))
       left join clavis.library l on(l.library_id=ci.owner_library_id)
       left join clavis.l_authority_manifestation lam on(lam.manifestation_id=cm.manifestation_id)
       left join clavis.authority a using(authority_id)
       left join clavis.l_manifestation lm on(lm.link_type=410
                 and lm.manifestation_id_down=cm.manifestation_id)
       left join clavis.lookup_value lv
         on(lv.value_key=lam.link_type::varchar and lv.value_language='it_IT'
            and value_class='LINKTYPE')
      where cm.manifestation_id=#{self.id}
      order by lam.link_type}
    # Valutare se fare una view
    # puts sql
    connection.execute(sql).to_a
  end

  # http://www.germane-software.com/software/rexml/docs/tutorial.html
  def export_to_metaopac
    # puts "export_to_metaopac: #{self.id}"
    rec=Document.new "<record/>"
    rec.root.attributes['id']=self.id
    rec.root.attributes['cod_polo']='BCT'
    rec.root.attributes['data']=Time.now
    rec.root.attributes['biblevel']=self.bib_level
    rec.root.attributes['date_updated']=self.date_updated

    if bid_source=='SBN'
      e=Element.new('bid')
      e.text=self.bid
      rec.root.add_element e
    end

    unixml=REXML::Document.new(self.unimarc.sub(%Q{<?xml version=\"1.0\"?>},''))
    elements=unixml.first.elements

    {
      'd010/sa'  => 'isbn',
      'd011/sa'  => 'issn',
    }.each do |k,f|
      v=unixml.elements.first.elements[k]
      next if v.blank?
      # puts "#{k} (#{f}): #{v.text}"
      e=Element.new(f)
      e.text=v.text
      rec.root.add_element e
    end

    #isbn=unixml.elements.first.elements['d010/sa'].text

    # 'chiave_esterna' => :id,


    ret=self.reticolo
    {
      'titolo'         => :title,
      'editore'        => :publisher,
    }.each do |k,f|
      v=self.send(f)
      next if v.blank?
      e=Element.new(k.to_s)
      e.text = v.class==String ? v.strip : v
      rec.root.add_element e
    end

    copie_array=(ret.collect {|r| [r['collocazione'],r['inventario'],r['library_code']]}).uniq    
    copie=Document.new "<copie/>"
    copie_array.each do |r|
      collocazione,inventario,library_code=r
      d=Document.new "<copia/>"
      d.root.attributes['library']=library_code
      e=Element.new('colloc'); e.text=collocazione; d.root.add_element e
      e=Element.new('invent'); e.text=inventario; d.root.add_element e
      copie.root.add_element d
    end

    links_array=(ret.collect {|r| [r['link_type'],r['authority'],r['authtype']]}).uniq
    links=Document.new "<links/>"
    links_array.each do |r|
      uni,content,type=r
      next if content.blank?
      d=Document.new "<link/>"
      d.root.attributes['unimarc']=uni
      d.root.attributes['type']=type
      e=Element.new('authority')
      e.text=content
      d.root.add_element e
      links.root.add_element d
    end

    rec.root.add_element copie if ['a','m'].include?(self.bib_level)

    rec.root.add_element links if links.first.elements.size>0

    if self.bib_level=='c'
      lts=Document.new "<linked_titles/>"
      (ret.collect {|r| [r['manifestation_id_up'],r['link_sequence']]}).uniq.each do |r|
        m_id,seq=r
        d=Document.new "<title/>"
        d.root.attributes['seq']=seq
        d.root.attributes['id']=m_id
        lts.root.add_element d
      end
      rec.root.add_element lts
    end

    s=''
    rec.write s
    # puts s
    rec
  end

  def talking_book
    sql=%Q{select tb.* from clavis.manifestation cm join clavis.item ci using(manifestation_id)
     join libroparlato.catalogo tb on(tb.n=replace(ci.collocation,'CD ','')) where ci.section='LP'
      AND cm.manifestation_id=#{self.id}}
    TalkingBook.find_by_sql(sql).first
  end

end
