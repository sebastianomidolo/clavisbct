# coding: utf-8
# -*- mode: ruby;-*-

desc 'Importa da DNG'

task :allinea_dng => :environment do
  puts "#{Time.now} allinea_dng --> INIZIO"
  dng_workdir = "/tmp/allinea_test/dng_mysql_tables"
  pg_dng_tables_dir = "/tmp/allinea_test/pg_dng_tables"
  FileUtils.mkpath dng_workdir
  FileUtils.mkpath pg_dng_tables_dir

  imp = ClavisImport::Import.new
  force = true

  puts "#{Time.now} allinea_dng --> chiamo uncompress_dng_sql_dumpfile"
  ret = imp.uncompress_dng_sql_dumpfile
  puts "#{Time.now} allinea_dng <-- tornato da uncompress_dng_sql_dumpfile (ret=#{ret})"
  if ret==true
    imp.delete_semaphore(dng_workdir)
    imp.drop_schema_dng_import
  end

  puts "#{Time.now} allinea_dng --> chiamo mysql_dng_dbdump_parse(#{dng_workdir},force=#{force})"
  imp.mysql_dng_dbdump_parse(dng_workdir,force=force)
  puts "#{Time.now} allinea_dng <-- tornato da mysql_dng_dbdump_parse(#{dng_workdir},force=#{force})"

  puts "#{Time.now} allinea_dng --> chiamo insert_dng_into_postgresql(#{dng_workdir},force=#{force})"
  imp.insert_dng_into_postgresql(dng_workdir,force=force)
  puts "#{Time.now} allinea_dng <-- tornato da insert_dng_into_postgresql(#{dng_workdir},force=#{force})"

  puts "CREATE TABLE clavis_dng_patrons"
  sql = %Q{CREATE TABLE IF NOT EXISTS import_dng.clavis_dng_patrons AS
select "ID" as dng_member_id, p.patron_id
  from import_dng."Member" m
  join clavis.patron p on(p.patron_id = substr("External_Anchor", 8)::integer)
where "External_Anchor" ~ '^patron:';
create unique index clavis_dng_patrons_member_id on  import_dng.clavis_dng_patrons (dng_member_id);
create unique index clavis_dng_patrons_patron_id on  import_dng.clavis_dng_patrons (patron_id);}
  imp.connection.execute(sql)
  puts "#{Time.now} allinea_dng --> FINE"
end
