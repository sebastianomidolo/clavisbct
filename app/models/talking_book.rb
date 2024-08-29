# coding: utf-8

include DigitalObjects

require 'mp3info'

class TalkingBook < ActiveRecord::Base
  self.table_name='libroparlato.catalogo'
  self.primary_key = 'id'
  attr_accessible :n, :intestatio, :titolo, :respons, :edizione, :editore, :collana, :isbn, :cassette, :richiamo1, :richiamo2, :soggetto, :soggetto2, :dewey, :note, :lingua, :chiave, :ordine, :abstract, :lettore, :utente, :stampa_bollini, :cd, :da_inserire_in_informix, :non_disponibile, :bid, :manifestation_id, :data_collocazione, :data_ritiro, :data_consegna, :digitalizzato, :talking_book_reader_id
  
  before_save :controlla_collocazione
  
  has_many :attachments, :as => :attachable
  has_many :downloads, class_name:'TalkingBookDownload', foreign_key:'title_id'
  belongs_to :d_objects_folder
  belongs_to :talking_book_reader

  has_many :clavis_items
  
  def clavis_items_no
    sql=%Q{select ci.* from libroparlato.catalogo c join clavis.item ci on
 (ci.custom_field1!='' and ci.manifestation_id=c.manifestation_id and
  ci.custom_field1::integer=c.id and item_media='T' and section='LP')
    where c.id=#{self.id}}
    ClavisItem.find_by_sql(sql)
  end

  def controlla_collocazione
    self.n=self.n.squeeze(' ').strip
  end

  def main_entry
    # self.intestatio.blank? ? "#{self.titolo}" : "#{self.intestatio}. "
    self.intestatio.blank? ? "" : "#{self.intestatio.titleize}. "
  end

  def digitalized
    self.digitalizzato.nil? ? false : true
  end

  def collocazione
    # "#{self.n} - #{self.titolo}"
    # self.cd.nil? ? self.n : "#{self.cd} CD #{self.n}"
    self.cd.nil? ? self.n : "CD #{self.n}"
  end

  def area_descrizione_fisica_tex
    res=[]
    res << "#{self.n} [#{self.cassette}~cass.]" if !cassette.nil?
    if !cd.nil?
      res << "CD#{self.n} [#{self.cd}~cd~mp3]"
      if res.size==0
        # res << "#{self.n} [#{self.cd}~CD~mp3]"
      else

      end
    end
    return '' if res.size==0
    "#{res.join(' -- ')}"
  end

  def codice_opera
    self.n
  end

  def titolo_completo
    return self.titolo if self.manifestation_id.nil?
    self.clavis_manifestation.title.strip
  end

  def clavis_manifestation
    return nil if self.manifestation_id.nil?
    ClavisManifestation.find(self.manifestation_id)
  end

  def manifestation_id_da_collocazione
    self.n
  end

  def build_readme_file
    str=File.read(File.join(Rails.root.to_s,'extras','talking_book_readme.txt.erb'))
    erb = ERB.new(str)
    record=self
    erb.result(binding).gsub("\n", "\r\n")
    TalkingBook.loadhelper
    word_wrap(erb.result(binding)).gsub("\n", "\r\n")
  end

  def zip_filepath(patron=nil)
    return nil if self.manifestation_id.nil?
    return nil if !patron.nil? and patron.loan_class!='@'
    if patron.nil?
      uid = ''
      # mid = "tb_#{self.id}_mid_#{self.manifestation_id}"
      mid = "tb_#{self.n.gsub(' ','').downcase}"
      config = Rails.configuration.database_configuration
      path = config[Rails.env]["libroparlato_download_area_basedir"]
    else
      uid = "_uid_#{patron.id}"
      mid = "mid_#{self.manifestation_id}"
      path = DigitalObjects.digital_objects_cache
    end
    File.join(path, "#{mid}#{uid}.zip")
  end

  def attachments_insert
    return nil if self.manifestation_id.nil?
    sql=%Q{
         DELETE FROM public.attachments WHERE attachable_id=#{self.manifestation_id}
          AND attachment_category_id='D' AND attachable_type='ClavisManifestation';
         INSERT INTO public.attachments
         (d_object_id,attachable_id,attachable_type,attachment_category_id,position)
          (select d_object_id,#{self.manifestation_id},'ClavisManifestation','D',position
           from public.import_libroparlato_colloc where collocation = '#{self.collocazione}');}
    puts sql
    ActiveRecord::Base.connection.execute(sql)
    self.update_d_objects_folder_id
  end

  # Aggiornamento zip audio singolo libro parlato:
  # tb=TalkingBook.find(11083);tb.book_update
  def book_update(folder=nil)
    config = Rails.configuration.database_configuration
    source=config[Rails.env]["libroparlato_upload"]
    mount_point=config[Rails.env]["digital_objects_mount_point"]
    destfolder=File.join(mount_point,'libroparlato')
    if folder.nil?
      if self.d_objects_folder_id.nil?
        raise "parametro 'folder' mancante per #{self.class} #{self.id} (self.d_objects_folder_id è NULL)"
      end
      folder=self.d_objects_folder.name.sub(/^libroparlato\//,'')
    end
    puts "aggiornamento da source #{source} a destfolder #{destfolder}"
    puts "folder di provenienza: #{folder}"

    target=File.dirname(folder)
    puts "source: #{source}"
    puts "target: #{target}"
    puts "destfolder: #{destfolder}"
    puts "mount_point: #{mount_point}"

    source_folder=File.join(source,folder)
    target_folder=File.join(destfolder,target)
    old_folder=File.join(target_folder,File.basename(folder))

    puts "source_folder: #{source_folder}"
    if !Dir.exists?(source_folder)
      puts "non aggiornabile, non esiste #{source_folder}, proseguo con i files già presenti"
    else
      if Dir.exists?(old_folder)
        puts "cancello #{old_folder}"
        FileUtils.remove_dir(old_folder)
      end
      puts "Aggiorno da #{source_folder}"
      puts "a: #{target_folder}"
      FileUtils.cp_r(source_folder,target_folder,{preserve:true})
    end
    scan_dir=old_folder.sub(mount_point,'')
    puts "nuovo scan da effettuare in #{scan_dir}"
    numfiles=DObject.fs_scan(scan_dir)
    puts "Analizzati e importati nel db #{numfiles} files"

    collocazione=TalkingBook.filename2colloc(folder)
    collocazione = "CD #{collocazione}" if (collocazione =~ /^CD /).nil?
    puts "ora inserisco collocazione #{collocazione} in tabella import_libroparlato_colloc"

    newdestfolder=ActiveRecord::Base.connection.quote_string(scan_dir)
    puts "newdestfolder: #{newdestfolder}"
    sql=%Q{DELETE FROM import_libroparlato_colloc WHERE collocation='#{collocazione}';
           INSERT INTO import_libroparlato_colloc(collocation,position,d_object_id)
       (SELECT '#{collocazione}',row_number() over(order by win_sortfilename(o.name)), o.id
         from d_objects_folders f join d_objects o on(o.d_objects_folder_id=f.id)
           where f.name LIKE '#{newdestfolder}%');}
    puts sql

    ActiveRecord::Base.connection.execute(sql)
    self.attachments_insert

    cm=self.clavis_manifestation
    puts "Aggiorno mp3tags per #{cm.title} (t_book: #{self.id} = manifestation_id #{cm.id})"
    cm.write_mp3tags_libroparlato
    self.create_or_replace_audio_zip
  end

  def collocation_from_filename
    return nil if self.d_objects_folder_id.nil?
    TalkingBook.filename2colloc(self.d_objects_folder.name)
  end

  def create_or_replace_audio_zip
    if File.exists?(self.zip_filepath)
      puts "Cancello audiozip: #{self.zip_filepath}"
      File.delete(self.zip_filepath)
    end
    puts "Creo audiozip: #{self.zip_filepath}"
    self.make_audio_zip
    # group 33 => www-data
    File.chown(nil, 33, self.zip_filepath) if File.exists?(self.zip_filepath)
  end

  def update_d_objects_folder_id
    puts "update_d_objects_folder_id: #{self.clavis_manifestation.id}"
    return nil if self.clavis_manifestation.nil?
    atch = self.clavis_manifestation.attachments
    puts "ok procedo - #{atch.first}"

    return nil if atch.nil?
    a = atch.where(attachment_category_id:'D',attachable_type: "ClavisManifestation").order('position').first
    return nil if a.nil?
    self.d_objects_folder_id=a.d_object.d_objects_folder_id
    self.save if self.changed?
  end

  def make_audio_zip(patron=nil)
    return nil if self.manifestation_id.nil?
    return nil if !patron.nil? and patron.loan_class!='@'

    require 'zip'
    zipfile_name = self.zip_filepath(patron)
    return true if File.exists?(zipfile_name)

    cm=ClavisManifestation.find(self.manifestation_id)
    tempdir=Dir.mktmpdir('make_audio_zip', File.join(Rails.root.to_s, 'tmp'))
    storage_dir=DigitalObjects.digital_objects_mount_point
    title=cm.title.strip
    d_objects=cm.d_objects(nil, "a.attachment_category_id='D'")
    cnt=0
    d_objects.each do |o|
      FileUtils.cp(File.join(storage_dir, o.filename), tempdir)
      cnt+=1
    end
    totale=cnt
    cnt=0
    d_objects.each do |o|
      cnt+=1
      fname=File.join(tempdir, File.basename(o.filename))
      if !['application/octet-stream; charset=binary','audio/mpeg; charset=binary'].include?(o.mime_type)
        puts "non mp3: #{o.filename} - #{o.mime_type}"
        next
      end
      puts "acquisisco informazioni su mp3 file: #{o.filename} - #{o.mime_type}"
      mp3=Mp3Info.open(fname)
      # see: /var/lib/gems/1.9.1/gems/ruby-mp3info-0.8/lib/mp3info.rb
      # and: /var/lib/gems/1.9.1/gems/ruby-mp3info-0.8/lib/mp3info/id3v2.rb
      mp3.tag.album="#{self.n} - #{title}"
      mp3.tag.title="traccia #{cnt} di #{totale}"
      mp3.tag.artist=self.intestatio
      mp3.tag.tracknum=cnt
      mp3.tag.year=self.digitalizzato.year if !self.digitalizzato.nil?
      if patron.nil?
        mp3.tag2.TCOP="Biblioteche civiche torinesi"
      else
        mp3.tag2.TCOP="Biblioteche civiche torinesi - utente #{patron.id}"
      end
      # "WOAS" => "Official audio source webpage"
      # "TCON" => "Content type"
      # "TPOS" => "Part of a set"
      # "TBPM" => "BPM (beats per minute)"
      # "COMM" => "Comments"

      mp3.tag2.WOAS="https://clavisbct.comperio.it/talking_books/#{self.id}"
      mp3.tag2.TCON='Audiobook'
      mp3.tag2.TPOS=1                  ;# Disc number, sempre 1
      mp3.tag2.TBPM=mp3.bitrate
      if patron.nil?
        mp3.tag2.COMM="Registrazione a uso esclusivo degli utenti del Servizio libro parlato delle BCT"
      else
        mp3.tag2.COMM="Registrazione a uso esclusivo degli utenti del Servizio libro parlato delle BCT (utente #{patron.id})"
      end
      mp3.close
      # puts mp3.to_s
    end

    tf = Tempfile.new("readme_zip",tempdir)
    readme_filename=tf.path
    fdout=File.open(readme_filename,'w')
    fdout.write(self.build_readme_file)
    fdout.close

    folder_title=cm.title.split("/").first.strip
    to_be_deleted=[]
    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      zipfile.add(File.join(folder_title, "LEGGIMI.txt"), readme_filename)
      to_be_deleted << readme_filename
      cnt=0
      d_objects.each do |o|
        cnt+=1
        bname=File.basename(o.filename)
        sourcefile=File.join(tempdir, bname)
        fname = File.join(folder_title, bname)
        # puts fname
        zipfile.add(fname, sourcefile)
        to_be_deleted << sourcefile
      end
    end
    puts zipfile_name
    to_be_deleted.each do |f|
      # puts "da cancellare: #{f}"
      #cmd="/usr/bin/id3info #{f}"
      #puts cmd
      #Kernel.system(cmd)
      File.delete(f)
    end
    Dir.delete(tempdir)
    tf.close(false)
  end


  def TalkingBook.filename2colloc(fname)
    regexp_collocazione = /(NA|NB|NT|MP|MD) +((\d+)[ -]|(\d+$))/
    regexp_collocazione =~ fname
    if $1=='MP'
      p="CD MP"
    else
      p=$1
    end
    num=$2.to_i
    "#{p} #{num}"
  end

  def TalkingBook.pdf_catalog(talking_books)
    lp=LatexPrint::PDF.new('talkingbooks_catalog', talking_books)
    fd=File.open("/tmp/prova.tex","w")
    fd.write(lp.texinput)
    fd.close
    lp.makepdf(3)
  end

  def TalkingBook.digitalizzati_non_presenti_su_server
    sql=%Q{select *,'' as descr_fisica, '' as collocations, '' as item_ids, '' as opac_visibilities
     from libroparlato.catalogo where digitalizzato notnull
      and cd notnull and d_objects_folder_id is null and n!= '' order by
       espandi_collocazione(n)}
    TalkingBook.find_by_sql(sql)
  end

  def TalkingBook.digitalizzati
    sql=%Q{SELECT * FROM libroparlato.catalogo WHERE manifestation_id IN
      (SELECT attachable_id FROM attachments WHERE attachable_type='ClavisManifestation' AND attachment_category_id='D')
      ORDER BY chiave,ordine
    }
    TalkingBook.find_by_sql(sql)
  end

  def TalkingBook.updated_at
    return Time.now.to_date
    config = Rails.configuration.database_configuration
    begin
      File.mtime(config[Rails.env]["libroparlato_mdb_filename"]).to_date
    rescue
      logger.warn("Errore: #{$!}")
      lastmode=Time.now.to_date
    end
  end

  def TalkingBook.d_objects_folders
    sql=%Q{select id,name from d_objects_folders where name ~ '^libroparlato'}
    collocazioni={}
    ActiveRecord::Base.connection.execute(sql).each do |r|
      colloc=TalkingBook.filename2colloc(r['name'])
      next if colloc==' 0'
      # puts "#{r['id']} #{colloc} #{r['name']}"
      if !collocazioni[colloc].nil?
        # puts "Collocazione duplicata #{collocazioni[colloc].class} '#{colloc}'"
        if collocazioni[colloc].class!=Array
          val=collocazioni[colloc]
          collocazioni[colloc] = Array.new
          collocazioni[colloc] << val
        end
        collocazioni[colloc] << r['id'].to_i
      else
        collocazioni[colloc] = r['id'].to_i
      end
    end
    collocazioni
  end

  def TalkingBook.build_pdf_catalogs
    cmd="(cd #{File.join(Rails.root,'extras','libroparlato')};make clean;make;ls -lh *.pdf)"
    Open3.capture3(cmd)
  end

  def TalkingBook.logfilename
    tempdir = File.join(Rails.root.to_s, 'tmp')
    File.join(tempdir, 'libroparlato.log')
  end

  def TalkingBook.auto_insert_covers_i05(attachment_id)
    outfile='/tmp/insert_covers_cassette.sql'
    fd=File.open(outfile, 'w');
    puts fd=File.open('/tmp/insert_covers_cassette.sql', 'w');
    sql=%Q{select m.* from clavis.manifestation m join clavis.item i using(manifestation_id)
         left join clavis.attachment a on(a.object_id=m.manifestation_id) where a.attachment_id is null and m.bib_type='i05'
           and i.item_media='T'}
    cm=ClavisManifestation.find_by_sql(sql)
    cm.each do |m|
      fd.write(m.clone_attachment_sql(attachment_id))
    end
    fd.close
    puts "ok scritto sql in #{outfile}"
  end



  # Vedi https://regex101.com/
  def TalkingBook.read_apache_log(fname=nil)
    puts "entro in TalkingBook con fname=#{fname}"
    if fname.nil?
      Dir.glob("/var/log/apache2/tbda-access.log*").each do |fn|
        next if fn =~ /gz$/
        TalkingBook.read_apache_log(fn)
      end
      return
    end
    # 109.116.9.71 - username [13/Oct/2022:20:56:45 +0200] "GET /tbda/tb_mp755.zip? HTTP/1.1" 200 594140903
    format = /([^ ]+) - ([^ ]+) \[([^ ]+) ([^ ]+)\] \"(GET|POST) ([^ ]+) ([^ ]+)\" (\d+) (\d+)/
    sql = []
    File.readlines(fname).each do |line|
      if !line.match(format)
        puts "formato irregolare: #{line}"
        sql << "insert into libroparlato.downloads (logline) values (#{self.connection.quote(line)}) on conflict(logline) do nothing;"
      else
        c = line.match(format).captures
        ip,username,date,timezone,method,http_path,protocol,http_status,filesize = c
        sql << "insert into libroparlato.downloads (ip,username,date,timezone,method,http_path,protocol,http_status,filesize,logline) values ('#{ip}','#{username}','#{date}','#{timezone}','#{method}','#{http_path}','#{protocol}','#{http_status}','#{filesize}',#{self.connection.quote(line)}) on conflict(date, username, http_path) do nothing;"
      end
    end
    # sql << "update libroparlato.downloads set http_path = trim(http_path, '?') where http_path is not null;";
    sql << "update libroparlato.downloads d set title_id = t.id from libroparlato.catalogo t where substring(d.http_path, '_(.*).zip')=lower(replace(n,' ',''));"
    self.connection.execute(sql.join("\n"))
    nil
  end
  
  def self.loadhelper
    include ActionView::Helpers::TextHelper
  end
end
