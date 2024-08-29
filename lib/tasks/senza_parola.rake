# coding: utf-8
# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake senza_parola
# In production:
# RAILS_ENV=production  rake senza_parola

desc 'Importazione bibliografie da SenzaParola'

task :senza_parola => :environment do
  puts "Importazione bibliografie da SenzaParola - Non usare, altrimenti viene cancellato il lavoro già presente"
  exit
  # SpBibliography.sync_all(1)
  sql=%Q{
    BEGIN;
      DELETE FROM sp.sp_users;
      DELETE FROM sp.sp_bibliographies;
      SELECT setval('sp.sp_bibliographies_id_seq',1);
      SELECT setval('sp.sp_items_id_seq',1);
    ROLLBACK;
  }
  puts sql
  # SpBibliography.sync_all

  sql=%Q{
     UPDATE sp.sp_items i set manifestation_id=m.manifestation_id from clavis.manifestation m
      where m.bid=i.sbn_bid and i.manifestation_id is null;
  }
  puts "Eseguire: #{sql}"
  
  #SpBibliography.connection.execute("SELECT setval('sp.sp_bibliographies_id_seq', (select max(id) from sp.sp_bibliographies));")

  # SpBibliography.delete_empty_bibliographies
  puts "importazione completata"
end
