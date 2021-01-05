# -*- mode: ruby;-*-
# lastmod 10 agosto 2012
# lastmod  9 agosto 2012
# lastmod  8 agosto 2012
# lastmod  7 agosto 2012

desc 'Esportazione dati da file access .mdb e creazione tabelle postgresql'

task :mdb_export => :environment do

  # puts Rails.env
  include AccessImport
  files=Dir.glob(File.join(Rails.root.to_s,'lib','data','musicale','*'))
  # files=Dir.glob(File.join(Rails.root.to_s,'lib','data','musicale','letteratura'))
  files.each do |fname|
    # next if fname!="/home/ror/bctaudio/lib/data/musicale/cr_attrezzature"
    next if fname!="/home/ror/bctaudio/lib/data/musicale/periodici_musicale_old"
    puts "---- file sorgente dati: #{fname}"
    af=AccessImport::AccessFile.new(fname)
    if File.exists?(af.sql_outfilename)
      # puts "file esistente: #{af.sql_outfilename}"
      File.delete(af.sql_outfilename)
    end
    af.create_pg_schema
    af.tables.each do |t|
      puts "tabella #{t}"
      af.drop_pg_table(t)
      af.create_pg_table(t)
      af.sql_copy(t)
    end
  end

  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  cmd=%Q{cat mdb_export_*.sql | psql --quiet --no-psqlrc #{dbname} #{username} -f -; rm -f mdb_export_*.sql}
  cmd=%Q{cat mdb_export_*.sql | psql --quiet --no-psqlrc #{dbname} #{username} -f -; # rm -f mdb_export_*.sql}
  puts cmd
  Kernel.system(cmd)

  sql=%Q{
-- ALTER TABLE archivio_mp3.archivio_dischi ADD COLUMN record_id SERIAL PRIMARY KEY;
ALTER TABLE bm_letteratura.t_volumi add primary key(id_volumi);
ALTER TABLE bm_audiovisivi.t_volumi add primary key(idvolume);
}
  begin
    ActiveRecord::Base.connection.execute(sql)
  rescue
    puts "errore #{$!}"
    puts sql
  end
  # ActiveRecord::Base.connection.execute(File.read("lib/sql/mdb_items.sql"))

  puts "****************** schemi presenti sul db:"
  ActiveRecord::Base.connection.execute("SELECT schema_name FROM information_schema.schemata ORDER BY schema_name").each do |r|
    puts r['schema_name']
  end


end



