# -*- mode: ruby;-*-
# lastmod 11 febbraio 2013

# RAILS_ENV=production rake import_from_clavis
# http://stackoverflow.com/questions/399396/can-you-get-db-username-pw-database-name-in-rails

desc 'Importazione dati Clavis'

task :import_from_clavis => :environment do
  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  source=config[Rails.env]["clavis_datasource"]
  log=File.join('/','tmp',"import_from_clavis_#{Rails.env}")
  cmd="/usr/bin/psql --quiet -d #{dbname} #{username}  -f #{source} -L #{log} -w"
  puts cmd
  Kernel.system(cmd)
end
