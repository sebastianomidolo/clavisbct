# -*- mode: ruby;-*-

# RAILS_ENV=development rake libroparlato_tags | psql clavisbct_development informhop
# RAILS_ENV=production  rake libroparlato_tags | psql clavisbct_production informhop

desc 'Tags per libro parlato'

task :libroparlato_tags => :environment do
  sql=%Q{select * from d_objects where filename ~* 'libroparlato' order by filename;}

  flog='/tmp/export_libroparlato_colloc.log'
  fd=File.open(flog,'w')
  ttable='public.import_libroparlato_colloc'
  puts "-- output di libroparlato_tags.rake / logfile: #{flog}"
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
  fd.close

end

