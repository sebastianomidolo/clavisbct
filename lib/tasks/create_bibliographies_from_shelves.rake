# coding: utf-8
# -*- mode: ruby;-*-

desc 'Creazione automatica di bibliografie a partire da scaffali Clavis'

task :create_bibliographies_from_shelves => :environment do
  sql = %Q{select l.label, shelf_status,s.library_id,shelf_id,shelf_name,shelf_description
     from clavis.shelf s join clavis.library l using(library_id)
     where shelf_itemtype='manifestation' and shelf_status in ('B','D','E','F')
    order by s.library_id desc;}
  puts sql
  prec_library_id=-1
  number=1
  ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
    bibname="Scaffali #{r['label']}"
    library_id=r['library_id']
    if library_id != prec_library_id
      number=1
      puts "Creo o aggiorno bibliografia '#{bibname}'"
      prec_library_id=library_id
    else
      number += 1
    end
    bib = SpBibliography.find_or_create_by_title_and_library_id(bibname, r['library_id'])
    bib.status='A'; bib.save
    section = SpSection.find_or_create_by_bibliography_id_and_parent_and_title_and_description_and_clavis_shelf_id_and_number(bib.id,0,r['shelf_name'],r['shelf_description'],r['shelf_id'],number,status:'1')
    puts " --> #{section.number} - #{section.title}"
    section.save
  end
end
