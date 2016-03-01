# -*- coding: utf-8 -*-
# lastmod 20 febbraio 2013

include DigitalObjects
include REXML

class ClavisManifestation < ActiveRecord::Base
  attr_accessible :bid, :bid_source, :manifestation_id, :title
  self.table_name = 'clavis.manifestation'
  self.primary_key = 'manifestation_id'


  # self.per_page = 10

  has_many :clavis_items, :foreign_key=>'manifestation_id'
  has_many :clavis_issues, :foreign_key=>'manifestation_id'

  has_many :attachments, :as => :attachable

  has_and_belongs_to_many(:audio_visuals, :join_table=>'av_manifestations',
                          :foreign_key=>'manifestation_id',
                          :association_foreign_key=>'idvolume');

  has_many :ordini, foreign_key: 'manifestation_id'

  has_many :clavis_consistency_notes, foreign_key: 'manifestation_id'

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

  def kardex_adabas_2011_url
    "http://10.106.68.96:9000/fascicoli?bid=#{self.bid}"
  end

  def iccu_opac_url
    return nil if !['SBN','SBNBCT'].include?(self.bid_source)
    template="http://www.sbn.it/opacsbn/opaclib?db=solr_iccu&rpnquery=%2540attrset%2Bbib-1%2B%2540attr%2B1%253D1032%2B%2540attr%2B4%253D2%2B%2522IT%255C%255CICCU%255C%255C__POLO__%255C%255C__NUMERO__%2522&select_db=solr_iccu&nentries=1&rpnlabel=Preferiti&resultForward=opac%2Ficcu%2Ffull.jsp&searchForm=opac%2Ficcu%2Ferror.jsp&do_cmd=search_show_cmd&brief=brief&saveparams=false&&fname=none&from=1"
    template.sub!('__POLO__',bid[0..2])
    template.sub('__NUMERO__',numero=bid[3..9])
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
    if fnames.size==0
      self.attachments_folders.each do |folder|
        dobs=self.d_objects(folder, "mime_type ~* '^application/pdf'")
        dobs.each do |ar|
          fnames << fname=File.join(DObject.digital_objects_mount_point, ar.filename)
        end
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
    ClavisManifestation.clavis_url(self.id,mode)
  end

  def kardex_adabas_issues_count
    ClavisManifestation.connection.execute("SELECT count(*) from kardex_adabas where bid='#{self.bid}'")[0]['count'].to_i
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
      clipfn=o.digital_object_create_libroparlato_audioclip(40)
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

  def write_mp3tags_libroparlato
    storage_dir=DigitalObjects.digital_objects_mount_point
    lp=self.talking_book
    return nil if lp.nil?
    title=lp.titolo.strip
    totale=0
    self.d_objects.each do |o|
      next if o.attachment_category_id!='D' or o.mime_type!='audio/mpeg; charset=binary'
      totale+=1
    end
    
    cnt=0
    self.d_objects.each do |o|
      next if o.attachment_category_id!='D' or o.mime_type!='audio/mpeg; charset=binary'
      fname=File.join(storage_dir, o.filename)
      cnt+=1
      tstamp=File.mtime(fname)
      begin
        mp3=Mp3Info.open(fname)
      rescue
        puts "Errore d_object #{o.id}: #{$!}"
        next
      end
      next if mp3.tag2.WOAS == self.clavis_url(:opac)
      puts %Q{#{cnt} "#{fname}"}
      mp3.tag.album="#{lp.n} - #{title}"
      mp3.tag.title="traccia #{cnt} di #{totale}"
      mp3.tag.artist=lp.intestatio
      mp3.tag.tracknum=cnt
      mp3.tag.year=lp.digitalizzato.year if !lp.digitalizzato.blank?
      mp3.tag2.TCOP="Biblioteche civiche torinesi - Servizio del libro parlato"
      mp3.tag2.WOAS=self.clavis_url(:opac)
      mp3.tag2.TCON='Audiobook'
      mp3.tag2.TPOS=1                  ;# Disc number, sempre 1
      mp3.tag2.TBPM=mp3.bitrate
      mp3.tag2.COMM="Registrazione a uso esclusivo degli utenti del Servizio libro parlato delle BCT"
      mp3.close
      # FileUtils.touch(fname, :mtime=>tstamp)
    end
  end

  def oggbibl_5
    sql=%Q{select lv.value_label from clavis.manifestation cm join clavis.lookup_value lv
     on(lv.value_key=bib_type and value_language='it_IT' AND value_class='OGGBIBL_5')
      where manifestation_id =#{self.id}}
    r=connection.execute(sql).first
    r.nil? ? nil : r['value_label']
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

  def cover_id
    sql=%Q{SELECT attachment_id FROM clavis.attachment WHERE object_type='Manifestation' AND object_id=#{self.id}}
    r=self.connection.execute(sql).to_a.first
    return nil if r.nil?
    r['attachment_id'].to_i
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

  def self.clavis_url(id,mode=:show)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    r=''
    if mode==:show
      r="#{host}/index.php?page=Catalog.Record&manifestationId=#{id}"
    end
    if mode==:edit
      r="#{host}/index.php?page=Catalog.EditRecord&manifestationId=#{id}"
    end
    if mode==:add_subscription
      r="#{host}/index.php?page=Acquisition.SubscriptionInsertPage&manifestationId=#{id}"
    end
    if mode==:opac
      host=config[Rails.env]['clavis_host_dng']
      r="#{host}/opac/detail/view/sbct:catalog:#{id}"
    end
    r
  end

  def self.creators
    self.connection.execute("SELECT created_by FROM clavis.manifestation_creators ORDER BY created_by").collect{|x| x['created_by']}
  end

  def containers_info
    sql=%Q{select cit.item_title as consistenza, c.label as contenitore, cl.description as deposito,
          ci.loan_alert_note as note, ci.item_id as item_id, c.prenotabile, ci.issue_description
         from clavis.item ci join container_items cit using(item_id,manifestation_id)
       join containers c on(cit.container_id=c.id) join clavis.library cl on(cl.library_id=c.library_id)
       where ci.manifestation_id=#{self.id} ORDER BY cit.row_number,cit.item_title}
    ClavisManifestation.find_by_sql(sql)
  end

  def self.clavis_subscription_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Acquisition.SubscriptionViewPage&id=#{id}"
  end

  def self.periodici_ordini(ordine_template,page_number=1,per_page=50,extra_sql_conditions='')
    conditions=[]
    ordine_template.attribute_names.each do |n|
      next if ordine_template[n].blank? or n=='titolo'
      v=ordine_template[n]
      conditions << "sat.#{n}=#{Ordine.connection.quote(ordine_template[n])}"
      if v.class==Fixnum
      else
      end
    end
    if extra_sql_conditions.size>0
      conditions << extra_sql_conditions
    end
    conditions=conditions.flatten.join(" AND ")
    where = conditions=='' ? 'WHERE false' : 'WHERE'
    ordine_template.anno_fornitura=2015 if ordine_template.anno_fornitura.nil?
    subscription_year=ordine_template.anno_fornitura
    sql=%Q{SELECT
      sat.id,sat.titolo,cm.title,cm.manifestation_id,cs.subscription_id,sat.numero_fattura,
        sat.importo_fattura,sat.fattura_o_nota_di_credito as tipodoc,sat.periodo,sat.formato,sat.note_interne,
        sat.data_emissione,sat.data_pagamento,sat.prezzo,sat.commissione_sconto,sat."CIG" as cig,
        sat.totale,sat.iva,sat.prezzo_finale,sat.numcopie,sat.ordnum,sat.ordanno,sat.ordprogressivo,
        cl.shortlabel as library,sat.stato,
  array_to_string(array_agg(ci.item_id || ' ' || ci.issue_status ||
     ' ' || date_part('day', now()-issue_arrival_date_expected) ||
     ' ' || case when ci.issue_arrival_date is null then '-' else ci.issue_arrival_date::text end ||
     ' ' || case when ci.issue_arrival_date_expected is null then '-' else ci.issue_arrival_date_expected::text end ||
     ' ' || case when i.invoice_id is null then 0 else i.invoice_id end), ',') as info_fattura
 FROM public.serials_admin_table as sat
  JOIN clavis.library cl using(library_id)
  LEFT JOIN clavis.manifestation cm USING(manifestation_id)
  LEFT JOIN clavis.item ci ON (ci.manifestation_id=cm.manifestation_id AND ci.issue_year='#{subscription_year}'
             AND ci.owner_library_id=sat.library_id)
    LEFT JOIN clavis.invoice i ON(i.invoice_id=ci.invoice_id)
    LEFT JOIN clavis.subscription cs ON(cs.manifestation_id=cm.manifestation_id
              AND cs.library_id=sat.library_id AND cs.year=#{subscription_year})
   #{where} #{conditions}
GROUP BY
      sat.id,sat.titolo,cm.title,cm.manifestation_id,cs.subscription_id,sat.numero_fattura,
        sat.importo_fattura,sat.fattura_o_nota_di_credito,sat.periodo,sat.formato,sat.note_interne,
        sat.data_emissione,sat.data_pagamento,sat.prezzo,sat.commissione_sconto,
        sat.totale,sat.iva,sat.prezzo_finale,sat.numcopie,sat.ordnum,sat.ordanno,sat.ordprogressivo,
        cl.shortlabel
  ORDER BY sat.titolo,cl.shortlabel,sat.data_emissione,sat.numero_fattura
    }
    fd=File.open("/tmp/prova.sql", "w")
    fd.write(sql)
    fd.close
    Ordine.paginate_by_sql(sql,:per_page=>per_page, :page=>page_number)
    # self.connection.execute(sql).to_a
  end


end
