include DigitalObjects

require 'mp3info'

class TalkingBook < ActiveRecord::Base
  self.table_name='libroparlato.catalogo'
  self.primary_key = 'id'
  has_one :clavis_item, :foreign_key=>'collocation', :primary_key=>'n'
  # has_one :clavis_manifestation, :through=>:clavis_item
  has_many :attachments, :as => :attachable

  def main_entry
    # self.intestatio.blank? ? "#{self.titolo}" : "#{self.intestatio}. "
    self.intestatio.blank? ? "" : "#{self.intestatio}. "
  end

  def digitalized
    self.digitalizzato.nil? ? false : true
  end

  def collocazione
    # "#{self.n} - #{self.titolo}"
    self.cd.nil? ? self.n : "#{self.cd} CD #{self.n}"
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
    cm=self.clavis_manifestations.first
    cm.nil? ? self.titolo : cm.title
  end

  def clavis_manifestations
    return [] if n.nil?
    inventory=self.n.split.last.to_i
    basecolloc=self.n.split.first
    series=["'NV#{basecolloc}'"]
    series << "'NVCD#{basecolloc}'" if !self.digitalizzato.blank?
    sql=%Q{SELECT cm.*
 FROM clavis.item ci JOIN clavis.manifestation cm
      using(manifestation_id) WHERE ci.inventory_number=#{inventory}
       -- AND ci.owner_library_id=29
       AND inventory_serie_id IN (#{series.join(',')}) ;}
    puts sql
    ClavisManifestation.find_by_sql(sql)
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
    d_objects=cm.d_objects
    cnt=0
    d_objects.each do |o|
      puts o.filename
      FileUtils.cp(File.join(storage_dir, o.filename), tempdir)
      cnt+=1
    end
    totale=cnt
    cnt=0
    d_objects.each do |o|
      cnt+=1
      fname=File.join(tempdir, File.basename(o.filename))
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

      mp3.tag2.WOAS="http://clavisbct.comperio.it/talking_books/#{self.id}"
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
    regexp_collocazione = /(NA|NB|NT|MP) +((\d+)[ -]|(\d+$))/
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
    lp.makepdf
  end

  def TalkingBook.digitalizzati
    sql=%Q{SELECT * FROM libroparlato.catalogo WHERE manifestation_id IN
      (SELECT attachable_id FROM attachments WHERE attachable_type='ClavisManifestation' AND attachment_category_id='D')
      ORDER BY chiave,ordine
    }
    TalkingBook.find_by_sql(sql)
  end

  def self.loadhelper
    include ActionView::Helpers::TextHelper
  end
end
