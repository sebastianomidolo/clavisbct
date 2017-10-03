# coding: utf-8
# -*- mode: ruby;-*-

# RAILS_ENV=development rake libroparlato_collocazioni | psql clavisbct_development informhop
# RAILS_ENV=production  rake libroparlato_collocazioni | psql clavisbct_production informhop

desc 'Creazione tabella import_libroparlato_colloc per libro parlato (non più usato)'

task :libroparlato_collocazioni => :environment do
  puts "libroparlato_collocazioni: non usare!"
  exit
  sql=%Q{select win_sortfilename(filename) as filename,id from d_objects where filename ~ '^libroparlato'
          order by win_sortfilename(filename);}

  ttable='public.import_libroparlato_colloc'
  puts "DROP TABLE #{ttable};"
  puts "CREATE TABLE #{ttable} (collocation varchar(128), d_object_id integer, position integer);"
  puts "COPY #{ttable} (collocation,position,d_object_id) FROM stdin;"
  pos=0
  prec=''
  ActiveRecord::Base.connection.execute(sql).each do |r|
    colloc=TalkingBook.filename2colloc(r['filename'])
    if colloc!=prec
      pos=0
      prec=colloc
    end
    pos+=1
    puts "#{colloc}\t#{pos}\t#{r['id']}"
  end
  puts "\\.\n"
  puts "CREATE INDEX #{ttable.sub('public.','')}_collocation_idx ON #{ttable} (collocation);"
end

