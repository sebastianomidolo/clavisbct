# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake senza_parola
# In production:
# RAILS_ENV=production  rake senza_parola

desc 'Importazione bibliografie da SenzaParola'

task :senza_parola => :environment do
  SpBibliography.sync_all(10)
  SpBibliography.delete_empty_bibliographies
  puts "importazione completata"
end


