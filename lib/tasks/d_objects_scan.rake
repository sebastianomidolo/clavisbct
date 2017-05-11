# -*- mode: ruby;-*-

desc 'Scansione oggetti digitali su filesystem'

task :d_objects_scan => :environment do

  ARGV.each { |a| task a.to_sym do ; end }
  folder=ARGV[1]
  puts folder
  numfiles=DObject.fs_scan(folder)
  puts "scansione oggetti digitali => totale files analizzati #{numfiles}"
end


