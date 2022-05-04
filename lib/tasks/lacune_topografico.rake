# coding: utf-8
# -*- mode: ruby;-*-

desc 'Lista di collocazioni non presenti in topografico e in clavis'

# Accesso via https://bctwww.comperio.it/mn/
task :lacune_topografico => :environment do
  ClavisItem.genera_lista_non_catalogati((1..830), ('A'..'G'),   '/usr/local/www/html/mn/lacune_monografie.txt', 2)
  ClavisItem.genera_lista_non_catalogati((1..500), ('LB'..'LM'), '/usr/local/www/html/mn/lacune_opuscoli.txt', 2)
end
