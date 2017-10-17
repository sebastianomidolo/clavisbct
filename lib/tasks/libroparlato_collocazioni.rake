# coding: utf-8
# -*- mode: ruby;-*-

# RAILS_ENV=development rake libroparlato_collocazioni | psql clavisbct_development informhop
# RAILS_ENV=production  rake libroparlato_collocazioni | psql clavisbct_production informhop

desc 'Creazione tabella import_libroparlato_colloc per libro parlato e creazione attachments'

task :libroparlato_collocazioni => :environment do
  sql=%Q{select f.name as filename,o.id from d_objects_folders f join d_objects o on(o.d_objects_folder_id=f.id)
      where f.name ~ '^libroparlato' order by f.id,win_sortfilename(o.name);}
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

  sql=%Q{delete from public.attachments where attachment_category_id = 'D'
     and attachable_type='ClavisManifestation' and d_object_id in
   (select o.id from d_objects o join d_objects_folders f on(o.d_objects_folder_id=f.id));
    INSERT INTO public.attachments
  (d_object_id,attachable_id,attachable_type,attachment_category_id,position)
  (
  select lp.d_object_id,ci.manifestation_id,'ClavisManifestation','D',lp.position
   from public.import_libroparlato_colloc lp join clavis.item ci
  on(replace(lp.collocation,'CD ','')=replace(ci.collocation,'CD ',''))
   join d_objects o on(lp.d_object_id=o.id)
   where section='LP' and home_library_id=2 and ci.manifestation_id NOT IN (0,449004,441874)
     and ci.item_status='F'
        and o.mime_type='audio/mpeg; charset=binary'
  );
  UPDATE libroparlato.catalogo AS lp SET first_mp3_filename=f.name || '/' || o.name
    FROM public.attachments a, d_objects o join d_objects_folders f on(f.id=o.d_objects_folder_id)
    WHERE lp.first_mp3_filename IS NULL
      AND a.attachable_type='ClavisManifestation'
      AND a.attachment_category_id='D' AND o.id=a.d_object_id AND a.position=1
      AND lp.manifestation_id=a.attachable_id;
  }
  puts sql
end
