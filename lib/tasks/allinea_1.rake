# coding: utf-8
# -*- mode: ruby;-*-

# Task derivato da import_from_clavis.rake il 10 dicembre 2023


desc 'Allinea dati da Clavis (test su schema clavis2)'


task :allinea_1 => :environment do
  puts "#{Time.now} allinea_1 --> INIZIO"
  
  imp = ClavisImport::Import.new

  workdir = "/tmp/allinea_test/mysql_tables"
  dng_workdir = "/tmp/allinea_test/dng_mysql_tables"
  pg_tables_dir = "/tmp/allinea_test/pg_tables"
  pg_dng_tables_dir = "/tmp/allinea_test/pg_dng_tables"

  FileUtils.mkpath workdir
  FileUtils.mkpath dng_workdir
  FileUtils.mkpath pg_tables_dir
  FileUtils.mkpath pg_dng_tables_dir

  force = false

  puts "#{Time.now} allinea_1 --> chiamo uncompress_clavis_sql_dumpfile(#{workdir})"
  ret = imp.uncompress_clavis_sql_dumpfile
  # ret = false
  puts "#{Time.now} allinea_1 <-- tornato da uncompress_clavis_sql_dumpfile (ret=#{ret})"
  if ret==true
    imp.delete_semaphore(workdir)
    imp.drop_schema_import
  end

  # force = true
  puts "#{Time.now} allinea_1 --> chiamo mysql_dbdump_parse(#{workdir},force=#{force})"
  imp.mysql_dbdump_parse(workdir,force=force)
  puts "#{Time.now} allinea_1 <-- tornato da mysql_dbdump_parse"

  # Inizia la sezione più lunga (circa 45 minuti da prove empiriche)
  # esempio, da 12:45:23
  #           a 13:30:02
  # force = true
  puts "#{Time.now} allinea_1 --> chiamo insert_into_postgresql(#{workdir},force=#{force})"
  imp.insert_into_postgresql(workdir,force=force)
  puts "#{Time.now} allinea_1 <-- tornato da insert_into_postgresql"

  # Arrivati a questo punto, abbiano nello schema "import" tutte le tabelle ricavate
  # dal dump del db clavis mysql e non ancora modificate
  # Alcune di queste tabelle devono essere manipolate e integrate con altri dati.
  # Devono anche essere create alcune tabelle non presenti in clavis ma utili per clavisbct
  #
  # Nella versione precedente al nuovo metodo di allineamento, alla tabella item vengono aggiunti i seguenti quattro campi:
  # talking_book_id             | integer
  # openshelf                   | boolean
  # digitalized                 | boolean
  # acquisition_year            | integer

  
  puts "#{Time.now} allinea_1 --> chiamo sql_scripts"
  imp.sql_scripts
  puts "#{Time.now} allinea_1 <-- tornato da sql_scripts"

  puts "#{Time.now} allinea_1 --> chiamo pg_tables_backup('import', #{pg_tables_dir})"
  # esempio, da: 19:06:15
  #           a: 19:10:54
  # imp.pg_tables_backup('import',pg_tables_dir)
  puts "#{Time.now} allinea_1 <-- tornato da pg_tables_backup"

  #puts "#{Time.now} allinea_1 --> chiamo pg_tables_restore('import','clavis2',#{pg_tables_dir})"
  #imp.pg_tables_restore('import', 'clavis2', pg_tables_dir)
  #puts "#{Time.now} allinea_1 <-- tornato da pg_tables_restore"
  
  puts "#{Time.now} allinea_1 --> FINE"

end
