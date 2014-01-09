include DigitalObjects

require 'mp3info'

class TalkingBook < ActiveRecord::Base
  self.table_name='libroparlato.catalogo'
  self.primary_key = 'id'
  has_one :clavis_item, :foreign_key=>'collocation', :primary_key=>'n'
  # has_one :clavis_manifestation, :through=>:clavis_item
  has_many :attachments, :as => :attachable

  def digitalized
    self.digitalizzato.nil? ? false : true
  end

  def collocazione
    "#{self.n} - #{self.titolo}"
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

  def zip_filepath(patron, clavis_manifestation)
    return nil if patron.loan_class!='@'
    cm=clavis_manifestation
    File.join(DigitalObjects.digital_objects_cache, "mid_#{cm.id}_uid_#{patron.id}.zip")
  end

  def make_audio_zip(patron, clavis_manifestation)
    return nil if patron.loan_class!='@'
    cm=clavis_manifestation

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
      mp3.tag.year=self.digitalizzato.year
      mp3.tag2.TCOP="Biblioteche civiche torinesi - utente #{patron.id}"
      # "WOAS" => "Official audio source webpage"
      # "TCON" => "Content type"
      # "TPOS" => "Part of a set"
      # "TBPM" => "BPM (beats per minute)"
      # "COMM" => "Comments"

      mp3.tag2.WOAS="http://clavisbct.comperio.it/talking_books/#{self.id}"
      mp3.tag2.TCON='Audiobook'
      mp3.tag2.TPOS=1                  ;# Disc number, sempre 1
      mp3.tag2.TBPM=mp3.bitrate
      mp3.tag2.COMM="Registrazione a uso esclusivo degli utenti del Servizio libro parlato delle BCT (utente #{patron.id})"
      mp3.close
      # puts mp3.to_s
    end

    # puts tempdir
    require 'zip'
    zipfile_name = self.zip_filepath(patron, cm)
    File.delete(zipfile_name) if File.exists?(zipfile_name)

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

  def self.loadhelper
    include ActionView::Helpers::TextHelper
  end
end
