# coding: utf-8
# -*- mode: ruby;-*-

desc 'Importazione dati csv musicale (marzo 2024)'

task :import_musicale => :environment do

  i=ClavisImport::Import.new
  # i.import_musicale("/home/seb/musicale/audiovisivi.csv")
  i.import_musicale("/home/seb/musicale/prova.csv")

  #csv = CSV.read("/home/seb/musicale/Lett\ e\ Musica\ a\ stampa.csv",{col_sep:';',encoding: "ISO8859-1"});nil
  #puts csv.class
  #cnt = 0
  #csv.each do |r|
  #  cnt += 1
  #  puts "r: #{r.inspect}"
  #  break if cnt == 4
  #end

  
  
end
