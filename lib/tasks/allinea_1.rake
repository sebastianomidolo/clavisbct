# coding: utf-8
# -*- mode: ruby;-*-

# Task derivato da import_from_clavis.rake il 10 dicembre 2023
# allo scopo di dividere in due fasi le operazioni di allineamento dati

desc 'Allinea dati da Clavis - fase 1 (test su schema clavis2)'


task :allinea_1 => :environment do
  imp = ClavisImport::Import.new
  workdir = "/tmp/allinea_test/mysql_tables"
  pgdump_file = "/tmp/import_dump.sql"
  pg_tables_dir = '/tmp/allinea_test/pg_tables'


  force = true

  imp.uncompress_clavis_sql_dumpfile
  imp.mysql_dbdump_parse(workdir,force=force)
  imp.insert_into_postgresql(workdir,force=force)

  imp.sql_scripts

  imp.pg_tables_backup('import',pg_tables_dir)

  # imp.create_pgdump(pgdump_file,force=true)
  # Per ora uso il finto schema clavis2, ma poi sarà clavis
  # Versione completa, che cancella lo schema e lo riscrive:
  # imp.restore_dump(pgdump_file,dest_schema='clavis2',force=true)

  # Versione che procede tabella per tabella:
  imp.pg_tables_restore('import', 'clavis2', pg_tables_dir)

  
  puts "FINE esecuzione task allinea 1 #{Time.now}"
end
