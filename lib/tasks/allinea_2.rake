# coding: utf-8
# -*- mode: ruby;-*-

# Task derivato da import_from_clavis.rake il 10 dicembre 2023
# allo scopo di dividere in due fasi le operazioni di allineamento dati

desc 'Importazione dati Clavis - allinea 2'

task :allinea_2 => :environment do
  i = ClavisImport::Import.new

  # i.pg_tables_restore('import', 'clavis2', '/tmp/allinea_test/pg_tables')
  i.sql_scripts

  puts "FINE esecuzione allinea_2.rake #{Time.now}"
end
