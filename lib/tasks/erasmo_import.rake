# -*- mode: ruby;-*-

desc 'Importazione dati unimarc da Erasmo'

task :erasmo_import => :environment do
  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]


  def create_import_tables
    sql=%Q{
     DROP TABLE temp_import_erasmo_unimarc_tags;
     DROP TABLE temp_import_erasmo_bibrecords;
     CREATE TABLE temp_import_erasmo_bibrecords(
         id char(8) primary key,
         leader char(24)
       );
     CREATE TABLE temp_import_erasmo_unimarc_tags(
         bibrecord_id char(8) not null references temp_import_erasmo_bibrecords,
         marctag char(3),
         indicator1 char(1),
         indicator2 char(1),
         subfields xml,
         content text
       );
    }
    ActiveRecord::Base.connection.execute(sql);
  end

  def elimina_newline(fname)
    marcfile=fname.sub(/.txt$/,'.marc')
    return if File.exists?(marcfile)
    cmd = "tr --delete '\r\n' < #{fname} > #{marcfile}"
    Kernel.system(cmd)
  end

  def elabora_marcfile(marcfile, fd_bibrecords, fd_unimarc_tags)
    puts "elaborazione #{marcfile}"
    reader = MARC::Reader.new(marcfile, :external_encoding => "UTF-8")
    cnt=0
    res = ''
    for record in reader
      cnt+=1
      # puts cnt
      record_id=record.fields('001').first.value

      # xml=record.to_marchash.to_xml(:root=>'record',:skip_types=>true, :skip_instruct=>true, :indent=>0)
      # fd_bibrecords.write("#{record.fields('001').first.value}\t#{record.leader}\t#{xml}\n")

      fd_bibrecords.write("#{record_id}\t#{record.leader}\n")

      record.fields.each do |field|
        if field.class==MARC::DataField
          subfields=[]
          field.subfields.each do |sf|
            subfields << [sf.code,sf.value]
          end
          fd_unimarc_tags.write("#{record_id}\t#{field.tag}\t#{field.indicator1}\t#{field.indicator2}\t#{subfields.to_xml(:root=>'fields',:skip_types=>true, :skip_instruct=>true, :indent=>0)}\t#{field.to_s[7..-1]}\n")
        else
          fd_unimarc_tags.write("#{record_id}\t#{field.tag}\t\\N\t\\N\t\\N\t#{field.value}\n")
        end
      end

    end
  end

  source_dir="/home/seb/centro_documentazione_pedagogica/unimarc"
  entries=Dir.entries(source_dir).delete_if {|z| ['.','..'].include?(z)}.sort
  entries.each do |entry|
    next if File.extname(entry)!=".txt"
    fname=File.join(source_dir,entry)
    elimina_newline(fname)
  end

  create_import_tables


  tempdir = File.join(Rails.root.to_s, 'tmp')
  tf_bibrecords = Tempfile.new("import",tempdir)
  tf_unimarc_tags = Tempfile.new("import",tempdir)

  # fd_bibrecords=File.open(tf_bibrecords.path,'w')
  fd_bibrecords=File.open("/tmp/bibrecords.sql",'w')

  # fd_unimarc_tags=File.open(tf_unimarc_tags.path,'w')
  fd_unimarc_tags=File.open("/tmp/unimarc_tags.sql",'w')

  fd_bibrecords.write("\\pset tuples_only t\n\\pset border 0\n\\pset pager f\nCOPY public.temp_import_erasmo_bibrecords (id,leader) FROM stdin;\n")
  fd_unimarc_tags.write("\\pset tuples_only t\n\\pset border 0\n\\pset pager f\nCOPY public.temp_import_erasmo_unimarc_tags (bibrecord_id,marctag,indicator1,indicator2,subfields,content) FROM stdin;\n")

  entries.each do |entry|
    next if File.extname(entry)!=".marc"
    elabora_marcfile(File.join(source_dir,entry), fd_bibrecords, fd_unimarc_tags)
  end

  fd_bibrecords.write("\\.\n")
  fd_unimarc_tags.write("\\.\n")

  fd_unimarc_tags.close
  fd_bibrecords.close

  tf_bibrecords.close
  tf_unimarc_tags.close

end
