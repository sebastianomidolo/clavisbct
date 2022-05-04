# coding: utf-8
# -*- mode: ruby;-*-

desc 'Genera sql UPDATES per clavis gestionale, al fine di inserire in item.custom_field1 il numero di record di libroparlato.catalogo'

task :fix_libroparlato_item_id => :environment do
  puts "ok fix_libroparlato_item_id"

  fname="/tmp/fix_libroparlato_item_1.sql"
  fdout=File.open(fname,'w')

  fdout.write "set search_path to clavis;\n"

  # Promemoria:
  # CREATE INDEX item_libroparlato_id_ndx ON clavis.item(custom_field1) WHERE item_media='T' and section='LP';

  # update item set custom_field1=NULL where item_media='T' and section='LP' and manifestation_id!=0 and custom_field1 notnull;
  
  sql = %Q{select c.manifestation_id as lp_mid,ci.manifestation_id,c.id as id_libroparlato,ci.item_id,ci.collocation
             from libroparlato.catalogo c join clavis.item ci on(ci.collocation=c.n) where ci.custom_field1 is null
               and ci.item_media='T' and ci.section='LP' and ci.manifestation_id=c.manifestation_id and c.n!=''}
  ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
    fdout.write "UPDATE item SET custom_field1 = #{r['id_libroparlato']} WHERE item_id=#{r['item_id']} AND custom_field1 is null;\n"
  end

  sql = %Q{select c.manifestation_id as lp_mid,ci.manifestation_id,c.id as id_libroparlato,ci.item_id,ci.collocation
             from libroparlato.catalogo c join clavis.item ci on(ci.collocation=c.n) where ci.custom_field1 is null
               and ci.item_media='T' and ci.section='LP' and ci.manifestation_id!=c.manifestation_id and c.n!=''}

  ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
    sql2="SELECT item_id,manifestation_id,collocation FROM clavis.item WHERE manifestation_id in (#{r['lp_mid']},#{r['manifestation_id']})"
    ActiveRecord::Base.connection.execute(sql2).to_a.each do |e|
      fdout.write "UPDATE item SET custom_field1 = #{r['id_libroparlato']} WHERE item_id=#{e['item_id']} AND custom_field1 is null;\n"
    end
  end

  fdout.close
  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  cmd="/usr/bin/psql --no-psqlrc -q -d #{dbname} #{username} -f #{fname}"
  puts "Eseguo #{cmd}"
  Kernel.system(cmd)

  fname="/tmp/fix_libroparlato_item_2.sql"
  fdout=File.open(fname,'w')

  fdout.write "\n-- Aggiungo i CD\nset search_path to clavis;\n"
  sql = %Q{select item_id,collocation,c.n,c.id as id_libroparlato from clavis.item ci join libroparlato.catalogo c
            on (substr(ci.collocation,4)=c.n) where item_media='T' and section='LP'
            and ci.manifestation_id!=0 and custom_field1 is null and c.n!=''}
  ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
    puts r.inspect
    fdout.write "UPDATE item SET custom_field1 = #{r['id_libroparlato']} WHERE item_id=#{r['item_id']} AND custom_field1 is null;\n"
  end
  fdout.close
  cmd="/usr/bin/psql --no-psqlrc -q -d #{dbname} #{username} -f #{fname}"
  puts "Eseguo #{cmd}"
  Kernel.system(cmd)
  
end

