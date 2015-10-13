# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake bio_iconografico
# In production:
# RAILS_ENV=production  rake bio_iconografico

desc 'Caricamento files bio-iconografico'

task :bio_iconografico => :environment do

  source_dir="/home/storage/preesistente/bct/BioIconografico/"



  def insert_into_digital_objects
    base = "/home/storage/preesistente/"
    sql="select * from bioiconografico b join bioiconografico_images i using (id)"
    cnt=0

    keys={
      id:'excel_id',
      seqnum:'seqnum',
      intestazione:'intestazione',
      luogo_nascita:'luogo_nascita',
      data_nascita:'data_nascita',
      luogo_morte:'luogo_morte',
      data_morte:'data_morte',
      luoghi_di_soggiorno:'luoghi_di_soggiorno',
      esistenza_in_vita:'esistenza_in_vita',
      qualificazioni:'qualificazioni',
      var1:'var1',
      var2:'var2',
      var3:'var3',
      var4:'var4',
      var5:'var5',
      luoghi_visitati:'luoghi_visitati',
      note:'note',
      altri_link:'altri_link',
    }

    ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
      cnt+=1
      next if !File.exists? r['filename']
      filename=r['filename'].sub(base,'')
      d=DObject.find_or_create_by_filename(filename)
      d.type="BioIconograficoCard"
      d.save if d.changed?
      b=BioIconograficoCard.find(d.id)
      b.tags={}.to_xml(root:'r',:skip_instruct => true, :indent => 0)

      keys.each_pair do |k,v|
        next if r[v].blank?
        cont=r[v].strip
        m="#{v}="
        if b.respond_to?(m)
          b.send(m,cont)
        else
          puts "metodo sconosciuto: #{m}"
        end
        # puts "#{k}=>#{v} (contenuto: '#{cont}') - method: #{m}"
      end

      b.lettera=File.basename(b.filename)[0]
      b.save
      puts "#{cnt} id #{b.id} => #{b.intestazione}"
    end
  end

  insert_into_digital_objects
  exit

  tempdir = File.join(Rails.root.to_s, 'tmp')
  tf = Tempfile.new("bioicon",tempdir)
  tempfile=tf.path
  puts source_dir
  # tempfile="/tmp/importa_files_bioicon.sql"
  fdout=File.open(tempfile,'w')

  numfiles=0

  def dirscan(dirname, fdout=nil)
    puts "analizzo dir #{dirname}"
    filecount=0
    Dir[(File.join(dirname,'*'))].each do |entry|
      if File.directory?(entry)
        filecount += dirscan(entry, fdout)
      else
        next if File.extname(entry)!=".jpg"
        id=entry.split('_').last.split('.').first
        # puts "entry: #{entry}"
        fdout.write "#{id}\t#{entry}\n"
        filecount += 1
      end
    end
    filecount
  end

  fdout.write(%Q{DROP TABLE public.bioiconografico_images;CREATE TABLE public.bioiconografico_images (id integer, filename varchar(240));\n})

  fdout.write(%Q{DROP TABLE public.bioiconografico;CREATE TABLE public.bioiconografico (id integer, seqnum integer,
       "intestazione" varchar(1240), "luogo_nascita" varchar(80), "data_nascita" varchar(80), "luogo_morte" varchar(80),
       "data_morte" varchar(80), "luoghi_di_soggiorno"text, "esistenza_in_vita" varchar(80), "qualificazioni" text,
     "var1" varchar(220), "var2" varchar(180), "var3" varchar(80), "var4" varchar(180), "var5" varchar(80),
     "luoghi_visitati" text, "link_scheda" varchar(180), "note" text, "altri_link" varchar(1240),
     "sigla_operatore" varchar(60), "num_scatola" integer);\n})

  excel_filename="/home/storage/preesistente/bct/BioIconografico/bioiconografico.xls"
  puts "excel file: #{excel_filename}"
  excel=Roo::Excel.new(excel_filename)
  sheet=excel.sheet(0)
  fields=[]
  sheet.row(1).each do |d|
    fields << d
  end

  fdout.write(%Q{COPY public.bioiconografico ("id", "seqnum", "intestazione", "luogo_nascita", "data_nascita",
    "luogo_morte", "data_morte", "luoghi_di_soggiorno", "esistenza_in_vita", "qualificazioni",
    "var1", "var2", "var3", "var4", "var5", "luoghi_visitati", "link_scheda", "note", "altri_link",
    "sigla_operatore", "num_scatola") FROM stdin;\n})
  (2..sheet.last_row).each do |rn|
    data=[]
    sheet.row(rn)[0..20].each do |d|
      # puts "#{d.class} contiene '#{d.inspect}'"
      if d.class==Spreadsheet::Link
        # puts "#{d.class} - #{d.methods}"
        # puts "url: #{d.url}"
        # puts "href: #{d.href}"
      end
      data << (d.nil? ? "\\N" : d.class==Float ? d.to_i : d.class==Spreadsheet::Link ? d.url : d.class==Date ? d : d.strip)
    end
    # puts "data: #{data.inspect}"
    fdout.write(data.join("\t").gsub("\n", '\r').gsub("\\0", "\\\\\\0"))
    fdout.write("\n")
  end
  fdout.write("\\.\n")

  fdout.write(%Q{COPY public.bioiconografico_images (id, filename) FROM stdin;\n})
  entries=Dir.entries(source_dir).delete_if {|z| ['.','..'].include?(z)}.sort
  entries.each do |entry|
    # puts entry
    fname=File.join(source_dir,entry)
    puts fname
    numfiles+=dirscan(fname, fdout)
  end
  fdout.write("\\.\n")

  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]

  cmd="/usr/bin/psql --no-psqlrc -d #{dbname} #{username}  -f #{tempfile}"
  Kernel.system(cmd)

  tf.close(true)
  puts "scansioni schede bio-iconogratico => totale files analizzati #{numfiles}"
end


