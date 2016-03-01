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

  def clavis_init(db,user)
    ['collocazione',
     'view_prestiti',
     'view_digitalizzati',
     'setup',
     'create_serials_admin_table',
     'ricollocazioni',
     'merge_tobi',
     'views'
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
  cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{source}"
  puts cmd
  puts "import_from_clavis, inizio esecuzione #{cmd}: #{Time.now}"
  Kernel.system(cmd)
  puts "import_from_clavis, fine esecuzione #{cmd}: #{Time.now}"

  insertdir=File.join(File.dirname(source),'inserts')
  puts insertdir
  Dir.glob(File.join(insertdir, "*.sql")).sort.each do |f|
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{f}"
    puts cmd
    puts "import_from_clavis, inizio esecuzione #{cmd}: #{Time.now}"
    Kernel.system(cmd)
    puts "import_from_clavis, fine esecuzione #{cmd}: #{Time.now}"
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

end
