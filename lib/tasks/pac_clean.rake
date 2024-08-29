# coding: utf-8
# -*- mode: ruby;-*-

desc 'Pulizia vecchi dati programma acquisti centro rete'

task :pac_clean => :environment do
  puts "Disabilitato"
  exit
  sql=%Q{select t.id_titolo,substr(t.titolo,1,20) as titolo,
   t.manifestation_id,
   c.supplier_id,
   c.order_status,
   count(id_copia)

from sbct_acquisti.copie c
 join sbct_acquisti.titoli t using(id_titolo)
 left join clavis.manifestation cm using(manifestation_id)
 left join clavis.item ci on(ci.manifestation_id = cm.manifestation_id)
 left join sbct_acquisti.l_titoli_liste tl on (tl.id_titolo=t.id_titolo)
 where t.id_titolo < 406040
  and t.target_lettura is null
  and t.created_by is null
  and t.updated_by is null
   and c.order_id is null
   and c.created_by is null
   and c.budget_id is null
   and c.supplier_id = 20
   and c.order_status = 'A'
   and ci is null
   and tl is null

group by 1,2,3,4,5
-- having count(id_copia) = 3
order by count(id_copia) desc, t.id_titolo desc;
}
  
  puts sql

  sq = []

  cnt = 0
  SbctTitle.find_by_sql(sql).each do |t|
    cnt += 1
    puts "#{cnt} Esamino titolo #{t.id}"
    sq << "BEGIN;\n-- id_titolo #{t.id} con #{t.count} copie"
    sq << "DELETE FROM sbct_acquisti.copie where id_titolo = #{t.id_titolo} and budget_id is null and order_status='A' and supplier_id=20 and order_id is null;"
    sq << "DELETE FROM sbct_acquisti.titoli where id_titolo = #{t.id_titolo};"
    sq << "COMMIT;"
  end
  fname = "/tmp/delete_titles_be_careful.sql"
  sql = sq.join("\n")
  fd = File.open(fname, "w")
  fd.write(sql)
  fd.close
  puts "#{cnt} titoli da cancellare - sql scritto in #{fname}"
end
