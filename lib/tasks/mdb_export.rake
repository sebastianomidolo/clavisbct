# -*- mode: ruby;-*-

desc 'Esportazione dati da file access .mdb e creazione tabelle postgresql'

task :mdb_export => :environment do
  include AccessImport
  # files=Dir.glob('/home/ror/bctaudio/lib/data/musicale/*')
  files=Dir.glob('/home/storage/preesistente/mdb/*')
  # files=Dir.glob(File.join(Rails.root.to_s,'lib','data','musicale','letteratura'))
  files.each do |fname|
    next if File.directory?(fname)
    puts "---- file sorgente dati: #{fname}"
    af=AccessImport::AccessFile.new(fname)
    File.delete(af.sql_outfilename) if File.exists?(af.sql_outfilename)
    puts af.sql_outfilename
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
  # cmd=%Q{cat mdb_export_*.sql | psql --quiet --no-psqlrc #{dbname} #{username} -f -; rm -f mdb_export_*.sql}
  cmd=%Q{cat mdb_export_*.sql | psql --quiet --no-psqlrc #{dbname} #{username} -f -;}
  # cmd=%Q{cat mdb_export_*.sql | psql --quiet --no-psqlrc #{dbname} #{username} -f -; # rm -f mdb_export_*.sql}
  puts cmd
  Kernel.system(cmd)

  sql=%Q{
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

  #puts "****************** schemi presenti sul db:"
  #ActiveRecord::Base.connection.execute("SELECT schema_name FROM information_schema.schemata ORDER BY schema_name").each do |r|
  #  puts r['schema_name']
  #end

end



