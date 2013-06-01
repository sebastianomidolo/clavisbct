# -*- mode: ruby;-*-

# In development:
# RAILS_ENV=development rake allinea_collocazioni
# In production:
# RAILS_ENV=production  rake allinea_collocazioni

desc 'Allinea le collocazioni degli oggetti digitali in base al filename'

load 'extras/utils.rb'

task :allinea_collocazioni => :environment do
  # o=DObject.find(378460)
  # o=DObject.find(79493)
  sql = %Q{select * from d_objects where filename ~* '^mp3clips/' order by id;}
  # sql = %Q{select * from d_objects where id=323992;}
  # sql = %Q{select * from d_objects where id=323898;}
  DObject.find_by_sql(sql).each do |o|
    if (o.filename =~ /^libroparlato/)==0
      colloc=get_collocation('libroparlato',o.filename)
      puts "collocazione libro parlato: '#{colloc}'"
    end
    if (o.filename =~ /^mp3clips/)==0 and !o.tags.nil?
      doc = REXML::Document.new(o.tags)
      fname=doc.root.attributes['filepath']
      colloc=get_collocation('cdmusicale',fname)
      if colloc.blank?
        puts "colloc blank: #{o.id} #{fname}"
        next
      end
      xmlcolloc=doc.root.attributes['collocation']
      if colloc!=xmlcolloc
        puts "collocazione musicale #{o.id} => '#{colloc}' (in xml: '#{xmlcolloc}')"
        doc.root.attributes['collocation']=colloc
        o.tags=doc.to_s
        o.save if o.changed?
      else
        # puts "rimane uguale #{o.id} => '#{colloc}' (in xml: '#{xmlcolloc}')"
      end
      
    end
  end
end
