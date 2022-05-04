# coding: utf-8
# -*- mode: ruby;-*-

desc 'Genera files csv con dati dei prestiti per biblioteca, classe e anno di pubblicazione'

task :loans_per_library => :environment do
  ARGV.each { |a| task a.to_sym do ; end }
  edition_date = ARGV[1].to_i
  class_code = "^#{ARGV[2]}"
  class_code = ARGV[2]
  if class_code.nil?
    puts "Specificare anno di edizione e classe dewey (regexp), esempio '^30[0-9]'"
    exit
  end
  # search="^#{class_code.reverse.to_i.to_s.reverse}"
  search=class_code
  puts "class_code: #{class_code} - edition_date: #{edition_date} - search = '#{search}'"

  fname = File.join("/tmp/stats", "#{edition_date}.csv")
  puts fname
  csvdata=ClavisManifestation.loans_per_library(nil, search, edition_date)
  puts "#{fname} - csvdata.size: #{csvdata.size}"
  fd=File.open(fname, 'w')
  fd.write(csvdata)
  fd.close
  exit
  # Parte non eseguita (serviva a produrre files distinti per biblioteca)
  ClavisLibrary.where("library_internal='1'").each do |l|
    fname = File.join("/tmp/stats", "#{class_code}-#{edition_date}-#{l.label[5..-1]}.csv").gsub(' ', '_')
    puts fname
    csvdata=ClavisManifestation.loans_per_library(l.id, search, edition_date)
    puts "#{l.id} - #{l.label} - #{fname} - csvdata.size: #{csvdata.size}"
    next if csvdata.size < 100
    fd=File.open(fname, 'w')
    fd.write(csvdata)
    fd.close
  end

end

