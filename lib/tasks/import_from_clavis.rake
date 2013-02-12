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
  source=config[Rails.env]["clavis_datasource"]
  cmd=config[Rails.env]["clavis_getcmd"]
  puts cmd
  Kernel.system(cmd)

  cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{source}"
  puts cmd
  Kernel.system(cmd)
  insertdir=File.join(File.dirname(source),'inserts')
  puts insertdir
  Dir.glob(File.join(insertdir, "*.sql")).sort.each do |f|
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{f}"
    puts cmd
    Kernel.system(cmd)
  end

end
