# -*- coding: utf-8 -*-

desc 'Cancella immagini doppie tenendo la più recente'

task :bio_ico_fix_doppie => :environment do
  sql="select lettera,numero,array_agg(id order by id) as object_ids from bio_iconografico_cards where namespace = 'catarte' group by lettera,numero having count(*)>1;"

  ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
    ids=r['object_ids']
    ids.gsub!(/{|}/,'')
    old_id,new_id=ids.split(',')
    old=BioIconograficoCard.find(old_id)
    new=BioIconograficoCard.find(new_id)
    if new.filename.index('doppi').nil?
      puts "Lettera #{r['lettera']} - numero #{r['numero']}"
      puts "  anomalia #{old.id} #{User.find(old.xmltag('user')).email} #{old.filename} DA CANCELLARE? (#{old.f_ctime})"
      puts "  anomalia #{new.id} #{User.find(new.xmltag('user')).email} #{new.filename} DA RINOMINARE? (#{new.f_ctime})"
    else
      puts "Lettera #{r['lettera']} - numero #{r['numero']}"
      puts "  CANCELLO #{old.id} #{User.find(old.xmltag('user')).email} #{old.filename} (#{old.f_ctime})"
      old.destroy
      puts "  RINOMINO #{new.id} #{User.find(new.xmltag('user')).email} #{new.filename} (#{new.f_ctime})"
      new.intestazione=old.intestazione.gsub("&apos;", "'")
      new.save
    end
  end

end


