# coding: utf-8
# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake import_from_clavis 2> /tmp/import_from_clavis_development.stderr
# In production:
# RAILS_ENV=production rake import_from_clavis 2> /tmp/import_from_clavis_production.stderr

# http://stackoverflow.com/questions/399396/can-you-get-db-username-pw-database-name-in-rails

desc 'Importazione dati Clavis'

task :import_from_clavis => :environment do
  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]

  semaforo = "/home/seb/logs/esecuzione_in_corso"
  if ENV['ALLINEAMENTO']=='reboot'
    if File.exists?(semaforo)
      puts "REBOOT #{Time.now}: eseguo allineamento perché ho trovato #{semaforo} che indica che un precedente allineamento non è andato a buon fine"
    else
      puts "REBOOT #{Time.now}: NON eseguo allineamento perché il file #{semaforo} non esiste, e ciò significa che l'allineamento da crontab si è concluso"
      exit
    end
  else
    puts "Avvio allineamento normale da crontab alle #{Time.now}"
  end
  fd = File.open(semaforo, 'w');fd.write("#{Time.now}");fd.close


  # 'views',
  # 'export_bioicon',
  # 'centrale_locations',
  # 'dinotola'
 
  def clavis_init(db,user)
    ['collocazione',
     'view_prestiti',
     'view_digitalizzati',
     'setup',
     'sbct_views',
     'ricollocazioni',
     'merge_tobi',
     'views',
     'export_bioicon',
     'dinotola'
    ].each do |fname|
      sf=File.join(Rails.root.to_s, 'extras', 'sql', "clavis_#{fname}.sql")
      # cmd="/usr/bin/psql --no-psqlrc --quiet -d #{db} #{user}  -f #{sf}"
      cmd="/usr/bin/psql --no-psqlrc -d #{db} #{user}  -f #{sf}"
      puts "import_from_clavis, inizio esecuzione #{cmd}: #{Time.now}"
      Kernel.system(cmd)
      puts "import_from_clavis, fine esecuzione #{cmd}: #{Time.now}"
    end
  end

  source=config[Rails.env]["clavis_datasource"]
  cmd=config[Rails.env]["clavis_getcmd"]
  (puts cmd; Kernel.system(cmd)) if !cmd.blank?

  cmd=%Q{/usr/bin/psql -c "BEGIN" -c "DROP SCHEMA clavis CASCADE" -c "COMMIT" -c "CREATE SCHEMA clavis" #{dbname} #{username}}
  puts cmd
  Kernel.system(cmd)

  Dir.glob(File.join(source, "*.sql")).sort.each do |f|
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{f}"
    tab=File.basename(f)
    puts "import_from_clavis - inizio inserimento tabella #{tab}:\t\t #{Time.now}"
    Kernel.system(cmd)
    puts "import_from_clavis -   fine inserimento tabella #{tab}:\t\t #{Time.now}"
  end

  puts "import_from_clavis: chiamo clavis_init: #{Time.now}"
  clavis_init(dbname,username)
  puts "import_from_clavis: tornato da clavis_init: #{Time.now}"

  puts "chiamo ora Ordine.importa_archivio_periodici #{Time.now}"
  Ordine.importa_archivio_periodici
  puts "tornato da Ordine.importa_archivio_periodici #{Time.now}"


  puts "chiamo ora ClavisConsistencyNote.create_periodici_in_casse #{Time.now}"
  ClavisConsistencyNote.create_periodici_in_casse
  puts "tornato da ClavisConsistencyNote.create_periodici_in_casse #{Time.now}"
  puts "chiamo ora ClavisConsistencyNote.update_collocazione_per #{Time.now}"
  ClavisConsistencyNote.update_collocazione_per
  puts "tornato da ClavisConsistencyNote.update_collocazione_per #{Time.now}"

  puts "NON chiamo ora SchemaCollocazioniCentrale.update_all_centrale_locations #{Time.now}"
  # SchemaCollocazioniCentrale.update_all_centrale_locations
  puts "NON tornato da SchemaCollocazioniCentrale.update_all_centrale_locations #{Time.now}"

  puts "chiamo ora ClavisManifestation.update_url_sbn #{Time.now}"
  ClavisManifestation.update_url_sbn
  puts "tornato da ClavisManifestation.update_url_sbn #{Time.now}"

  puts "chiamo ora ClavisManifestation.update_all_isbd_cache #{Time.now}"
  cnt=ClavisManifestation.update_all_isbd_cache
  puts "tornato da ClavisManifestation.update_all_isbd_cache #{Time.now} - aggiornati #{cnt} records di public.isbd"

  puts "chiamo ora DailyCounter.reset #{Time.now}"
  DailyCounter.reset
  puts "tornato da DailyCounter.reset #{Time.now}"

  puts "chiamo ora ClosedStackItemRequest.status('on') #{Time.now}"
  ClosedStackItemRequest.status('on')
  puts "tornato da ClosedStackItemRequest.status('on') #{Time.now}"

  
  puts "chiamo ora SbctTitle.update_manifestation_ids #{Time.now}"
  SbctTitle.update_manifestation_ids
  puts "tornato da SbctTitle.update_manifestation_ids #{Time.now}"

  puts "chiamo ora SbctItem.set_clavis_item_ids #{Time.now}"
  SbctItem.set_clavis_item_ids
  puts "tornato da SbctItem.set_clavis_item_ids #{Time.now}"

  puts "chiamo ora ClavisPurchaseProposal.update_shelf e update_cpp #{Time.now}"
  ClavisPurchaseProposal.update_shelf(33942, '60 days')
  ClavisPurchaseProposal.update_cpp
  puts "tornato da ClavisPurchaseProposal.update_shelf e update_cpp #{Time.now}"

  puts "chiamo ora Location.update_all_items #{Time.now}"
  Location.update_all_items
  puts "tornato da Location.update_all_items #{Time.now}"

  puts "chiamo ora SbctList.autoremove_titles #{Time.now}"
  SbctList.autoremove_titles
  puts "tornato da SbctList.autoremove_titles #{Time.now}"

  cmd="/usr/bin/truncate -s0 /home/seb/autoprintweb.log"
  Kernel.system(cmd)

  puts "chiamo ora ClavisPatron.find_duplicates #{Time.now}"
  r=ClavisPatron.find_duplicates({library_id:'-1'}).total_entries
  fd=File.open('/home/seb/utenti_duplicati.txt', 'w')
  fd.write("#{r}")
  fd.close
  puts "tornato da ClavisPatron.find_duplicates #{Time.now}"



  
  puts "FINE esecuzione task import_from_clavis.rake #{Time.now}"
  File.delete(semaforo)
end
