# coding: utf-8
# -*- mode: ruby;-*-

desc 'Importazione dati csv musicale (marzo 2024)'

task :import_musicale => :environment do
  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]

  # csv = CSV.read("/home/seb/musicale/Lett\ e\ Musica\ a\ stampa.csv",{col_sep:';',encoding: "ISO8859-1"});nil
  csv = CSV.read("/home/seb/musicale/audiovisivi.csv",{col_sep:';',encoding: "ISO8859-1"});nil
  puts "csv size: #{csv.size}"
  cnt = 0
  csv.each do |r|
    cnt += 1
    puts "r class #{r.class}: #{r.inspect}"
    break if cnt == 4
  end


  #csv = CSV.read("/home/seb/musicale/Lett\ e\ Musica\ a\ stampa.csv",{col_sep:';',encoding: "ISO8859-1"});nil
  #puts csv.class
  #cnt = 0
  #csv.each do |r|
  #  cnt += 1
  #  puts "r: #{r.inspect}"
  #  break if cnt == 4
  #end

  
  
end
