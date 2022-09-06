# -*- coding: utf-8 -*-
# lastmod 20 febbraio 2013

include DigitalObjects
include REXML
include SoapClient

class ClavisManifestation < ActiveRecord::Base
  attr_accessible :bib_level, :bid, :bid_source, :manifestation_id, :title, :prestito_inizio_periodo, :prestito_fine_periodo, :prestito_max_titoli
  self.table_name = 'clavis.manifestation'
  self.primary_key = 'manifestation_id'

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

  def prestito_inizio_periodo
    self[:prestito_inizio_periodo]
  end

  def prestito_inizio_periodo=(val)
    self[:prestito_inizio_periodo] = convert_params_to_date(val)
  end

  def prestito_fine_periodo
    self[:prestito_fine_periodo]
  end

  def prestito_fine_periodo=(val)
    self[:prestito_fine_periodo] = convert_params_to_date(val)
  end

  def prestito_max_titoli
    self[:prestito_max_titoli]
  end

  def prestito_max_titoli=(val)
    self[:prestito_max_titoli] = val
  end

  def iccu_opac_url
    return nil if !['SBN','SBNBCT'].include?(self.bid_source)
    # return "http://opac.sbn.it/bid/#{self.bid}"
    return "https://opac.sbn.it/risultati-ricerca-avanzata/-/opac-adv/detail/ITICCU#{self.bid}"
    template="http://www.sbn.it/opacsbn/opaclib?db=solr_iccu&rpnquery=%2540attrset%2Bbib-1%2B%2540attr%2B1%253D1032%2B%2540attr%2B4%253D2%2B%2522IT%255C%255CICCU%255C%255C__POLO__%255C%255C__NUMERO__%2522&select_db=solr_iccu&nentries=1&rpnlabel=Preferiti&resultForward=opac%2Ficcu%2Ffull.jsp&searchForm=opac%2Ficcu%2Ferror.jsp&do_cmd=search_show_cmd&brief=brief&saveparams=false&&fname=none&from=1"
    template.sub!('__POLO__',bid[0..2])
    template.sub('__NUMERO__',numero=bid[3..9])
  end

  def form_richiesta_a_magazzino(opac_username,library_id)
    # return 'Civica Centrale: per richiedere il materiale bisogna autenticarsi con le proprie credenziali' if opac_username.blank?
    return '' if opac_username.blank?

    form_entries = {
      'name':854286914,
      'phone':708660104,
      'email':15851921,
      'title':58383296,
    }      
    uri= "https://docs.google.com/forms/d/e/1FAIpQLScUEdr4erxsLjXTwzJGU9Qm6ivxq3MsgOVqPgxykHV2kuOO3g/viewform?"

    req_ok=false
    self.clavis_consistency_notes.each do |r|
      next if r.library_id!=library_id
      if r.collocation =~ /P.G/
        req_ok=true
      end
    end
    return '' if !req_ok
    sql=%Q{SELECT "#{self.connection.quote(self.title)}" as title}
    uri << "entry.#{form_entries[:title]}=#{URI::encode(self.title)}"
    p=ClavisPatron.find_by_opac_username(opac_username)
    puts p.id
    return uri if p.nil?
    email=phone=''
    self.connection.execute("SELECT * FROM clavis.contact WHERE patron_id=#{p.id}").each do |r|
      phone=r['contact_value'] if r['contact_type']=='C' and phone.blank?
      email=r['contact_value'] if r['contact_type']=='E' and email.blank?
    end
    # puts "email: #{email} - phone: #{phone}"
    utente = "#{p.to_label} [barcode: #{p.barcode}]"
    uri << "&entry.#{form_entries[:name]}=#{URI::encode(utente)}"
    # uri << "&entry.#{form_entries[:email]}=#{URI::encode(email)}"
    # uri << "&entry.#{form_entries[:phone]}=#{URI::encode(phone)}"
    %Q{<a href=#{uri}>Modulo richiesta del periodico (solo per la Civica Centrale)</a>}
    return ''
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
          puts "Esiste #{fname}"
        else
          puts "Da creare #{fname}"
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

  def attachments_with_folders
    sql=%Q{
 select a.attachable_id,a.attachment_category_id,f.name as folder_name,f.id as folder_id,
 (case when
  (xpath('//r/cover_image/text()'::text, f.tags))[1] is not null
   then
      (xpath('//r/cover_image/text()'::text, f.tags))[1]::text::integer
   else
     null
 end)
  as cover_image_id,
  array_agg(o.id order by a.position) as "d_objects_ids", count(*)
  from attachments a join d_objects o on(a.d_object_id=o.id)
    join d_objects_folders f on(f.id=o.d_objects_folder_id) where attachable_type='ClavisManifestation'
  AND attachable_id=#{self.id}
  group by a.attachable_id,a.attachment_category_id,f.name,f.id,cover_image_id order by attachable_id desc;
}
    self.connection.execute(sql).to_a
  end

  def d_objects_folders
    DObjectsFolder.find_by_sql("select f.* from manifestations_d_objects_folders mf join d_objects_folders f on(f.id=mf.d_objects_folder_id) where mf.manifestation_id=#{self.id}")
  end

  def clavis_attachments_cache(destfolder)


    
  end

  def clavis_cover_cached
    folder=DObjectsFolder.find_by_name('ClavisCoversCache')
    fname = format('%08d',self.id)
    fullname = File.join(folder.filename_with_path, fname)
    if File.exists?(fullname) and File.size(fullname)>0
      obj = DObject.find_by_name_and_d_objects_folder_id(fname,folder.id)
    else
      uri=''
      if self.clavis_cover_id.nil?
        # Non esiste una copertina caricata come allegato, provo con EAN/ISBN
        ['EAN','ISBNISSN'].each do |nt|
          number=self.send(nt)
          uri="https://covers.comperio.it/calderone/viewmongofile.php?ean=#{number}" and break if !number.blank?
        end
      else
        uri="https://sbct.comperio.it/index.php?file=lcover&id=#{self.id}"
      end
      if !uri.blank?
        res = Net::HTTP.get_response(URI(uri))
        if res.class==Net::HTTPOK and res.body.size>185
          obj=DObject.new(d_objects_folder_id:folder.id, name:fname, access_right_id:0)
          obj.x_mid=self.id.to_s
          fd=File.open(fullname,'wb')
          fd.write(res.body)
          fd.close
          obj.save
        else
          obj = DObject.find(1034649)
        end
      end
    end
    obj
  end

  # Va chiamata controllando prima che ci sia almeno un attachment, altrimenti produce un errore
  def main_attachment
    f=self.attachments.first.d_object.d_objects_folder
    puts "x_mid per folder: #{f.x_mid}"
    if f.x_mid.to_i==self.id
      x=self.attachments.first.d_object.d_objects_folder.cover_image
    else
      x=nil
    end
    puts "x: #{x}"
    if x.blank?
      self.attachments.each do |a|
        puts ">>>#{a.d_object.x_mid}"
        if a.d_object.x_mid.to_i==self.id
          puts "trovato: #{a.d_object.id}"
          x=a
        end
      end
      x = self.attachments.first if x.nil?
      return x
    else
      return Attachment.find_by_attachable_type_and_attachable_id_and_d_object_id('ClavisManifestation',self.id,x.to_i)
    end
  end

  def clavisbct_cover
    # select * from attachments where attachable_id=50972 and attachable_type='ClavisManifestation' and attachment_category_id='F';
    DObject.find_by_sql(%Q{select o.* from attachments a join d_objects o on (o.id=a.d_object_id) where attachable_id=#{self.id} and attachable_type='ClavisManifestation' and attachment_category_id='F'}).first
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

  def sp_item_ids_with_d_objects
    sql=%Q{select distinct i.id from sp.sp_items i
     join public.attachments a on(i.manifestation_id=a.attachable_id) join
      public.d_objects o on(o.id=a.d_object_id) join
      public.d_objects_folders f on (f.id=o.d_objects_folder_id) where
      a.attachable_type='ClavisManifestation' and i.manifestation_id=#{self.id}
      and a.position=1 and (attachment_category_id!='F' or
      attachment_category_id is null);}
    self.connection.execute(sql).to_a.map {|i| i['id'].to_i}
  end

  def collocazioni_e_siglebib_per_senzaparola
    sql=%Q{SELECT cc.collocazione,
      array_to_string(array_agg(DISTINCT spl.sp_library_code ORDER BY spl.sp_library_code),',') as siglebib
         FROM clavis.manifestation cm JOIN clavis.item ci
          ON(cm.manifestation_id=ci.manifestation_id AND ci.opac_visible='1' AND ci.item_status IN ('F','G','K','V'))
        JOIN clavis.library l ON(l.library_id=ci.home_library_id)
            JOIN sp.sp_libraries spl ON(spl.clavis_library_id=l.library_id)
            JOIN clavis.collocazioni cc USING(item_id)
           WHERE cm.manifestation_id=#{self.id}
        GROUP BY cm.manifestation_id,cc.collocazione
           ORDER BY espandi_collocazione(cc.collocazione);}
    puts sql
    res={}
    collciv=[]
    self.connection.execute(sql).to_a.each do |r|
      c=r['collocazione']
      puts r.inspect
      if r['siglebib']=='Q'
        collciv << c
        next
      end
      res[c]=[] if res[c].nil?
      res[c] << r['siglebib']
    end
    res['collciv'] = collciv
    res['colldec'] = []
    siglebib=[]
    res.each_pair do |k,v|
      next if k=='collciv' or k=='colldec'
      puts "k: #{k}: #{v}"
      res['colldec'] << k
      siglebib << v[0]
      # siglebib << v.join
      puts "siglebib: #{siglebib} (v: #{v.inspect})"
    end
    res['sigle']=siglebib.join(',').split(',').uniq.sort.join
    if res['sigle']==''
      res['colldec']=nil
    else
      res['colldec']=res['colldec'].join(', ')
    end
    res['collciv']=res['collciv'].join(', ')
    res
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

  def update_isbd_cache
    begin
      sql = %Q{INSERT INTO public.isbd (manifestation_id) values(#{self.manifestation_id}) ON CONFLICT DO NOTHING;
        UPDATE public.isbd SET date_updated=#{self.connection.quote(self.date_updated)},
              isbd=#{self.connection.quote(to_isbd)} WHERE manifestation_id=#{self.manifestation_id};}
      self.connection.execute sql
      return 1
    rescue
      puts "Errore date update_isbd_cache, manifestation_id #{self.id} : #{$!}"
      return 0
    end
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

  def clavis_cover_id
    sql=%Q{SELECT attachment_id FROM clavis.attachment WHERE object_type='Manifestation' and attachment_type='E' AND object_id=#{self.id}}
    puts sql
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

  def clone_attachment_sql(from_attachment_id)
    sql=%Q{
     INSERT INTO attachment (attachment_type, object_id, object_type, mime_type, file_size, file_path,
                   file_label, file_description,
                  license, file_name, date_created, date_updated, created_by, modified_by)
      (SELECT attachment_type, #{self.id}, object_type, mime_type, file_size, file_path,
                  file_label, file_description,
                  license, file_name, now(), now(), created_by, 1
             FROM attachment WHERE attachment_id=#{from_attachment_id});
     UPDATE turbomarc_cache SET dirty=1 WHERE manifestation_id=#{self.id};
     }
    sql
  end

  # reload!;doc=ClavisManifestation.find(623049).unimarc_edit
  # doc.elements.first.elements
  def unimarc_edit
    context = {ignore_whitespace_nodes: :all, compress_whitespace: :all}
    doc=REXML::Document.new(self.unimarc.sub(%Q{<?xml version=\"1.0\"?>},''), context)
    nf = REXML::Element.new('d300', doc.root)
    sa = REXML::Element.new('sa', nf)
    sa.text = "<URL>iccu URL"

    
    return doc
    el = doc.root.elements['/r/d856']
    url  = el.get_elements('su').first.text
    nota = el.get_elements('sz').first.text
    # puts "URL: #{url['/su'].text}"
    puts "url: #{url}"
    puts "nota: #{nota}"
    doc
  end

  def to_isbd
    res=[]
    unixml=REXML::Document.new(self.unimarc.sub(%Q{<?xml version=\"1.0\"?>},''))
    elements=unixml.first.elements
    titolo=elements['d200/sa'].text
    luogo=elements['d210/sa'].text if !elements['d210/sa'].nil?
    editore=elements['d210/sc'].text if !elements['d210/sc'].nil?
    anno=elements['d210/sd'].text if !elements['d210/sd'].nil?

    res << self.title.strip
    # res << " / #{elements['d200/sf'].text}" if !elements['d200/sf'].nil?
    res << "#{luogo} : #{editore}, #{anno}"

    # Collazione
    coll=''
    # Pagine:
    coll << elements['d215/sa'].text if !elements['d215/sa'].blank?
    # Illustrazioni:
    coll << " : #{elements['d215/sc'].text}" if !elements['d215/sc'].blank?
    # Misura:
    # coll << " ; #{elements['d215/sd'].text.sub(/\.$/,'')}" if !elements['d215/sd'].blank?
    coll << " ; #{elements['d215/sd'].text}" if !elements['d215/sd'].blank?

    # Elemino eventuali "." finali della collazione:
    res << coll.sub(/\.+$/,'') if !coll.blank?

    res=res.join('. - ')
    # Collana:
    sql=%Q{select trim(cm.title) as title,lm.link_sequence from clavis.l_manifestation lm
   join clavis.manifestation cm on(lm.link_type=410 and lm.manifestation_id_down=cm.manifestation_id)
    where lm.manifestation_id_up=#{self.id};}
    r=ClavisManifestation.connection.execute(sql).to_a.first
    if !r.nil?
      collana=r['title']
      numseq=r['link_sequence']
      res << ". - (#{collana}"
      res << " ; #{numseq.strip}" if !numseq.blank?
      res << ")"
    end
    res << ". - ISBN #{self.ISBNISSN}" if !self.ISBNISSN.blank?
    ClavisManifestation.fix_sbn_isbd(res)
  end

  def ClavisManifestation.fix_sbn_isbd(src)
    # Fix errata formulazione elementi tra parentesi quadre (sbn-style), esempio:
    # \\1995! invece di [1995]
    res = src.gsub(/(\\)(\d+)+(!)/) { "[#{$2}]" }
    # oppure anche: [1995! invece di [1995]
    res.gsub(/(\[)(\d+)+(!)/) { "[#{$2}]" }.sub("' ", "'")
    # l'ultimo sub() elimina eventuali spazi dopo il primo apostrovo di un titolo, tipo "L' olfatto" => "L'olfatto"
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
       where ci.manifestation_id=#{self.id} and c.prenotabile ORDER BY cit.row_number,cit.item_title}
    sql=%Q{select cit.item_title as consistenza, c.label as contenitore, cl.description as deposito,
          ci.loan_alert_note as note, ci.item_id as item_id, c.prenotabile, ci.issue_description
         from clavis.item ci join container_items cit using(item_id,manifestation_id)
       join containers c on(cit.container_id=c.id) join clavis.library cl on(cl.library_id=c.library_id)
       where ci.manifestation_id=#{self.id} ORDER BY cit.row_number,cit.item_title}
    ClavisManifestation.find_by_sql(sql)
  end

  # Vale solo per i periodici Civica centrale con collocazione "Per", esempio "Per.15"
  def periodici_in_casse
    res = []
    self.clavis_consistency_notes.each do |r|
      res << r.casse
    end
    res.flatten.uniq
  end

  def unimarc_field(tag, subfield)
    doc = REXML::Document.new(self.unimarc)
    t = "d#{tag}"
    sf = "s#{subfield}"
    res = ''
    REXML::XPath.each(doc, "//r/#{t}") do |e|
      v = REXML::XPath.first(e, sf)
      next if v.nil?
      res = v.text.strip
    end
    res
  end

  def ClavisManifestation.unimarc_serial_frequencies_select
    sql=%Q{select label,code_value from clavis.unimarc_codes where language='it_IT' and field_number = 110 and pos=1 order by code_value;}
    self.connection.execute(sql).collect {|i| [i['label'],i['code_value']]}
  end

  def self.free_pdf_filename(manifestation_id)
    config = Rails.configuration.database_configuration
    "#{File.join(config[Rails.env]["digital_objects_cache"], 'free', manifestation_id)}.pdf"
  end

  def self.loans_per_library(library_id, class_code, edition_date)
    # Solo dal 300 al 309
    # Biblioteca,manifestation_id,ISBN,Titolo,Autore,Editore,CDD,Numero prestiti
    # Se library_id è nil, viene aggiunta in testa una colonna con il nome della biblioteca
    library_conditions = library_id.nil? ? '' : "and ci.home_library_id = #{library_id}"
    sql=%Q{select l.label as "Biblioteca",cm.manifestation_id,cm."ISBNISSN",cm.title,cm.author,cm.publisher,ca.class_code,
        count(cl.loan_id) as prestiti
  from clavis.item ci join clavis.manifestation cm using(manifestation_id)
       join clavis.l_authority_manifestation lam 
     on(lam.manifestation_id=cm.manifestation_id) join clavis.authority ca  
     on (ca.authority_id=lam.authority_id)
          left join clavis.loan cl on(cl.item_id=ci.item_id and cl.item_home_library_id=ci.home_library_id)
	  join clavis.library l on(l.library_id=ci.home_library_id)
       where ca.subject_class='676' and 
     ca.class_code ~ '#{class_code}' and cm.edition_date=#{edition_date}
     and ci.inventory_date between '#{edition_date}-01-01' and '#{edition_date}-12-31'
     #{library_conditions}
     group by l.label,cm.manifestation_id,cm."ISBNISSN",cm.title,cm.author,cm.publisher,ca.class_code
	  order by l.label,ca.class_code;}

    puts sql

    csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
      csv << ['Biblioteca','record_id','ISBN','Titolo','Autore','Editore','CDD','Numero prestiti']
      self.connection.execute(sql).to_a.each do |r|
        csv << [r['Biblioteca'],r['manifestation_id'],r['ISBNISSN'],r['title'],r['author'],r['publisher'],r['class_code'],r['prestiti']]
      end
    end
    csv_string
  end

  def ClavisManifestation.in_shelf(shelf_id,library_id=nil,limit=200)
    if library_id.nil?
      sql=%Q{select cm.title,cm.manifestation_id,cm.*,substr(array_to_string(array_agg(DISTINCT coll.collocazione
              ORDER BY coll.collocazione), ', '),1,512) as collocazione
	      from clavis.shelf_item si
   join clavis.manifestation cm on(cm.manifestation_id=si.object_id) join clavis.item ci using(manifestation_id)
    join clavis.collocazioni coll using(item_id)
     where si.object_class='manifestation' and si.shelf_id = #{shelf_id}
     group by cm.title,cm.manifestation_id LIMIT #{limit};}
    else
      sql=%Q{select cm.*,coll.collocazione from clavis.shelf_item si
             join clavis.manifestation cm on(cm.manifestation_id=si.object_id)
             left join lateral (SELECT item_id FROM clavis.item WHERE manifestation_id=cm.manifestation_id
                     AND home_library_id=#{library_id} and owner_library_id>0 limit 1) as items on true 
             left join clavis.collocazioni coll using(item_id)
             where si.object_class='manifestation' and si.shelf_id = #{shelf_id} LIMIT #{limit}}
    end
    puts sql
    ClavisManifestation.find_by_sql(sql)
  end

  def ClavisManifestation.update_url_sbn
    sql = %Q{SELECT manifestation_id, unimarc FROM clavis.manifestation where (unimarc ~ '<sa>&lt;URL&gt' or unimarc ~ '<d856')}
    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new('url_sbn',tempdir)
    outfile = tf.path
    fdout=File.open(outfile,'w')
    fdout.write "TRUNCATE clavis.url_sbn;\n"
    fdout.write "COPY clavis.url_sbn(manifestation_id,unimarc_tag,url,nota) FROM STDIN;\n"
    conn = ClavisManifestation.connection
    conn.execute(sql).to_a.each do |r|
      doc = REXML::Document.new(r['unimarc'].sub(%Q{<?xml version=\"1.0\"?>},''))
      unimarc_tag=url=nota=nil
      doc.root.elements.each do |el|
        next if !['d856','d300'].include?(el.name)
        if el.name == 'd300'
          iccu_url  = el.get_elements('sa').first.text
          next if (iccu_url =~ /^<URL> ?(.*)/).nil?
          nota, url = $1.split(' | ')
          if url.blank?
            url = nota
            nota = '\\N'
          end
          unimarc_tag='300'
        else
          url  = el.get_elements('su').first.text
          nota = el.get_elements('sz').first
          nota = nota.blank? ? '\\N' : (nota.text.blank? ? '\\N' : nota.text)
          unimarc_tag='856'
        end
      end
      next if unimarc_tag.nil?
      fdout.write "#{r['manifestation_id']}\t#{unimarc_tag}\t#{url}\t#{nota}\n"
    end
    fdout.write "\\.\n"
    fdout.close
    config   = Rails.configuration.database_configuration
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]
    cmd="/usr/bin/psql --no-psqlrc -d #{dbname} #{username} -f #{outfile}"
    Kernel.system(cmd)
  end

  def self.clavis_subscription_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Acquisition.SubscriptionViewPage&id=#{id}"
  end

  def self.bib_level
    sql=%Q{select value_label as label,value_key as key from clavis.lookup_value lv
       where value_language = 'it_IT' and value_class='LIVBIBL' order by value_key}
    self.connection.execute(sql).collect {|i| ["#{i['key']} - #{i['label']}",i['key']]}
  end

  def ClavisManifestation.update_all_isbd_cache
    sql = %Q{select cm.* from clavis.manifestation cm left join public.isbd i using(manifestation_id)
      where cm.manifestation_id>0 and cm.unimarc notnull and (i is null or cm.date_updated > i.date_updated)}
    cnt=0
    self.find_by_sql(sql).each {|m| cnt+=1;m.update_isbd_cache}
    cnt
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

  def ClavisManifestation.soap_get_manifestation_list_info(manifestation_ids_array)
    client = SoapClient::get_wsdl('catalog')
    r = client.call(:get_manifestation_list_info, message: {mids:manifestation_ids_array})
    # r = client.call(:get_shelves_for_library, message: {library_id:3})
    return r.body
    return nil if r.body[:get_manifestation_list_info_response][:return].nil?
    # r.body[:get_manifestation_list_info_response][:return][:item]
    r.body[:get_manifestation_list_info_response][:return]
  end

  def ClavisManifestation.piurichiesti
    sql=%Q{select cm.*,pr.*,t.id_titolo as acquisti_id_titolo from clavis.piurichiesti pr join clavis.manifestation cm using(manifestation_id)
            left join sbct_acquisti.titoli t using(manifestation_id)
        where pr.reqnum > pr.available_items order by pr.percentuale_di_soddisfazione;
    }
    self.find_by_sql(sql)
  end

  private
  # val può essere o un oggetto di tipo Date o una stringa nel formato "yyyy-mm-dd"
  def convert_params_to_date(val)
    if val.class==String
      val=val.split('-')
      val=Date.new(val[0].to_i,val[1].to_i,val[2].to_i)
    end
    val
  end
end
