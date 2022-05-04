# coding: utf-8
# -*- mode: ruby;-*-

# Iniziato ore 11:05 del 3 gennaio 2018

desc 'Creazione tabella con url (campi 856 e 300 in stile ICCU)'

task :url_sbn => :environment do
  ClavisManifestation.update_url_sbn
end
