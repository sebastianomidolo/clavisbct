# coding: utf-8
desc 'Aggiunge una entry nella tabella rfid_summary'

task :conta_esemplari_con_tag_rfid => :environment do
  sql=[]
  sql << "SET DATESTYLE TO DMY;"
  # La data di riferimento è quella del giorno precedente al momento dell'esecuzione del task,
  # visto che i dati sono aggiornati al giorno prima
  tm=Time.now - 1.day
  date="'#{tm.day}/#{tm.month}/#{tm.year}'"
  sql << "DELETE FROM rfid_summary WHERE snapshot_date=#{date};"
  ClavisItem.conta_esemplari_con_tag_rfid.each do |r|
    sql << "INSERT INTO rfid_summary (library_id, snapshot_date, tagged_count) VALUES(#{r['library_id']}, #{date}, #{r['count']});"
  end
  ActiveRecord::Base::connection.execute(sql.join)
end
