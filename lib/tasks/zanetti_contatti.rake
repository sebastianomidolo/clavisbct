# -*- mode: ruby;-*-

# Iniziato ore 11:05 del 3 gennaio 2018

desc 'Contatti UC Patrizia Zanetti'


require 'csv'


task :zanetti_contatti => :environment do

  cnt=0
  CSV.foreach("/home/seb/2018_01_export_contatti_da_UC.csv") do |row|
    cnt+=1
    next if cnt==1 or row.last=="false"
    category=row.first
    adr=row[90].split(';')
    adr.each_slice(2) do |email,name|
      out=%Q{BEGIN:VCARD
VERSION:3.0
CATEGORIES:#{category}
EMAIL;TYPE=work,pref:#{email}
N:#{name}
END:VCARD}
      puts out
    end
  end
end

