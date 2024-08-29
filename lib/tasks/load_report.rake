# coding: utf-8
# -*- mode: ruby;-*-

desc 'Aggiorna report logistico da Leggere - 29 giugno 2023'

task :load_report => :environment do
  csv_data_file = "/home/seb/tmp/downl/report.csv"
  sql_file = "/home/seb/tmp/downl/load_report.sql"
  puts "leggo csv da #{csv_data_file}"
  sql_data = SbctTitle.import_from_csv(csv_data_file,"sbct_acquisti.report_logistico",create_table=false,truncate_table=true)
  fd = File.open(sql_file, 'w')
  fd.write(sql_data)
  fd.write("update sbct_acquisti.report_logistico rl set id_titolo=t.id_titolo from sbct_acquisti.titoli t where t.ean=rl.codiceean and rl.id_titolo is null;\n");
  fd.close
  puts "OK fin qui"
  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  at_file = "/home/seb/tmp/downl/at_load_report.txt"
  fd = File.open(at_file,"w")
  fd.write("# Generato da load_report.rake - #{Time.now}\n\n")
  fd.write("LANG='en_US.UTF-8'\n")
  fd.write(%Q{/usr/bin/psql --no-psqlrc -d #{dbname} #{username} -f #{sql_file}\n})
  fd.close
  cmd = "at -f #{at_file} now + 1 minute"
  cmd = "at -f #{at_file} now"
  puts cmd
  Kernel.system(cmd)
end
