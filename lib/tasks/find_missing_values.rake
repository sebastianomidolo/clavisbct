# -*- mode: ruby;-*-
# lastmod 7 gennaio 2016: - http://bctdoc.comperio.it/issues/256
# lastmod 12 maggio 2015: - http://bctdoc.comperio.it/issues/240
# lastmod 6 febbraio 2015: - http://bctdoc.comperio.it/issues/191
# lastmod 17 luglio 2014: - http://bctdoc.comperio.it/issues/191
# lastmod 3 marzo 2014: disabilito "periodici_mancanti" (non viene usato)
# lastmod 7  gennaio 2014: - http://bctdoc.comperio.it/issues/136
# lastmod 20 dicembre 2013: - http://bctdoc.comperio.it/issues/134
# lastmod 29 agosto 2013 - http://bctdoc.comperio.it/issues/87
# lastmod 15 luglio 2013 - http://bctdoc.comperio.it/issues/58
# lastmod 17 giugno 2013 - http://bctdoc.comperio.it/issues/35 [trova_numeri.call('GIN',496,1) etc.]
# lastmod 23 luglio 2012 - Aggiungo condizione "AND manifestation_id NOTNULL" alle condizioni
#                          per il calcolo min/max dei numeri di inventario
# lastmod  5 luglio 2012 - Aggiungo "trova inventari duplicati"
# lastmod 26 giugno 2012
# lastmod 17 maggio 2012 - Aggiungo auth_opere_blanks
# lastmod 8 aprile 2012 - Aggiungo "archivia_html"
# lastmod 4 aprile 2012 - Aggiungo "periodici_mancanti"
# lastmod 2 aprile 2012 - Aggiungo "barcodes duplicati"
# lastmod 26 marzo 2012 - Aggiungo "barcodes errati"
# lastmod 16 marzo 2012 - Aggiungo "buchi_collocazione"
# lastmod 12 marzo 2012 - Aggiungo "trova autori duplicati" (non c'entra con gli inventari)
# lastmod  6 marzo 2012 - Aggiungo "trova bid duplicati" (non c'entra con gli inventari)
# lastmod 24 febbraio 2012
# lastmod 23 febbraio 2012

desc 'Trova valori mancanti in una sequenza di numeri in tabella'
task :find_missing_values => :environment do

  def trova_periodici_mancanti
    periodici_mancanti=lambda do |outdir,library_ids,tolleranza|
      return if library_ids==[]
      codes=ActiveRecord::Base.connection.execute("select library_code from clavis.library where library_id in (#{library_ids.join(',')})").collect {|x| x['library_code'][4..5]}
      outfile="#{outdir}/#{codes.join('_')}.html"
      # puts outfile
      sql=%Q{set search_path to clavis;
select substr(ci.title,1,32) as titolo,ci.manifestation_id as id,
 l.shortlabel as biblioteca, ci.barcode,
-- now()::date as rilevato_il,
  ci.issue_arrival_date_expected atteso_per,
 age(now()::date,ci.issue_arrival_date_expected) as ritardo,
 f.supplier_code as codforn
-- s.tolerance::text
  FROM issue i join item ci using(manifestation_id,issue_id)
 join library l on(l.library_id=ci.owner_library_id)
 LEFT join subscription s on(s.manifestation_id=ci.manifestation_id
    and l.library_id=ci.owner_library_id)
 LEFT join supplier f on(f.supplier_id=s.supplier_id)
  where i.issue_year in ('2012','2013','2014')
  and ci.owner_library_id in (#{library_ids.join(',')})
  and ci.issue_status='M' and
   age(now()::date,ci.issue_arrival_date_expected) > interval '#{tolleranza}'
 order by age(now()::date,ci.issue_arrival_date_expected) asc,ci.manifestation_id,ci.issue_arrival_date_expected,l.shortlabel;}
      # puts sql
      cmd=%Q{/usr/local/bin/psql -H -o #{outfile} -q -d informhop informhop --command "#{sql}"}
      # cmd=%Q{/usr/local/bin/psql -H -o #{outfile} -q -d informhop informhop --command "select now();"}
      # puts cmd
      Kernel.system(cmd)
      data=File.read(outfile)
      File.delete(outfile) and return if !data.index("(0 rows)").nil?
      quando=Time.now
      data=%Q{<html><head><meta http-equiv="content-type" content="text/html; charset=UTF-8"/><title>fascicoli non pervenuti - #{quando}</title></head><body><div>
<p>Data rilevazione: #{quando}<br/>Tolleranza: #{tolleranza}; i fascicoli sono ordinati per entit&agrave; del ritardo</p>#{data}</div></body></html>}
      fd=File.open(outfile,'w')
      fd.write(data)
      fd.close
    end
    # periodici mancanti (kardex - esemplari mancanti)
    outdir="/usr/local/www/html/mn/pm"
    Kernel.system("/bin/rm #{outdir}/*.html")
    ids=ActiveRecord::Base.connection.execute("select library_id from clavis.library where library_code like 'TO0%'").collect {|x| x['library_id']}
    periodici_mancanti.call(outdir,ids,'1 month')
    ids.each {|x| periodici_mancanti.call(outdir,[x],'15 days')}
    #cmd="(cd #{outdir}; cd ..; /usr/bin/tar zcf pm.tar.bz2 pm)"
    #Kernel.system(cmd)
  end

  trova_numeri=lambda do |serie,library,min_filter|
    table='clavis.item'
    number="inventory_number"
    conn=InfoTable.connection
    sql = "select shortlabel from clavis.library where library_id=#{library}"
    libname=conn.execute(sql).collect.first['shortlabel']
    libname="%02d_#{libname.strip}" % library
    puts libname
    outfile="/usr/local/www/html/mn/#{libname}_#{serie}_missing_numbers.txt"

    if File.exists?(outfile)
      File.delete(outfile)
    end

    filter="inventory_serie_id='#{serie}' and owner_library_id=#{library}"
    #min_filter=1; # normalmente il valore minimo e' >= 1
    #min_filter=280000; # per la serie 01 della civica centrale

    # datefilter="AND inventory_date between '2011-11-14' and '2012-01-01'"
    # datefilter="AND inventory_date > '2011-11-14'"
    # datefilter="AND inventory_date > '2010-01-01'"
    datefilter=""
    conditions="#{number} notnull AND #{filter} #{datefilter} AND manifestation_id!=0"
    report_conditions=conditions.split("AND").join("\n  AND ")
    # puts "condizioni iniziali per min e max: #{conditions}"

    sql="SELECT max(#{number}) FROM #{table} WHERE #{conditions};"
    puts sql

    max=conn.execute(sql).collect.first['max']
    # puts "max: #{max}"
    return if max.nil?
    sql="SELECT min(#{number}) FROM #{table} WHERE #{number}>=#{min_filter} AND #{conditions};"
    # puts sql
    min=conn.execute(sql).collect.first['min']
    return if min.nil?
    max=max.to_i
    min=min.to_i

    conditions="#{number} between #{min} and #{max} AND #{filter}"

    puts "condizioni min/max: #{conditions}"

    report_conditions << "\n min/max: #{min}/#{max}\n"

    aggiornato_il=conn.execute("select max(inventory_date) as date from #{table}").collect.first['date']

    # sql="CREATE table sequenza_numeri (id integer);"
    sql="TRUNCATE TABLE public.sequenza_numeri;"
    # puts sql
    conn.execute(sql)
    file="/tmp/sequenza_numeri.sql"
    fd=File.open(file, "w")
    fd.write("COPY public.sequenza_numeri (id) FROM stdin;\n")
    (min..max).each do |n|
      fd.write("#{n}\n")
    end
    fd.write("\\.\n")
    fd.close
    cmd="/usr/local/bin/psql -q -d informhop informhop  -f #{file}"
    # puts cmd
    Kernel.system(cmd)

    sql=%Q{select id from public.sequenza_numeri where id not in
 (select #{number} from #{table} where #{conditions}) order by id;}
    # puts sql

    tmpfile="/usr/local/www/html/missing_numbers.tmp"
    fd=File.open(tmpfile,"w")
    # fd.write("Report prodotto il #{Time.now.to_date} (su dati aggiornati al #{aggiornato_il})\n\n")
    # fd.write("Condizioni:\n#{report_conditions}\n\n")
    # fd.write("min_filter: #{min_filter}\n\n") if min_filter>1
    cnt=0
    conn.execute(sql).each do |r|
      fd.write("#{serie}-#{r['id']}\n")
      # fd.write("#{r['id']}\n")
      cnt+=1
      if cnt>1000
        fd.write("Attenzione\n interrompo\nstampa\nnumeri\nperche'\nsono\ntroppi\nmax:\n#{max}")
        break;
      end
    end
    fd.close

    return if File.size(tmpfile)==0
    # cmd=%Q{pr -8 -a -F -l 74 -s" " -h "(#{filter})" #{tmpfile} > #{outfile}}
    cmd=%Q{pr -5 -a -F -l 74 -h "(Serie '#{serie}' #{min}-#{max})" #{tmpfile} > "#{outfile}"}
    puts cmd
    Kernel.system(cmd)
  end

  def missing_numbers
    buchi_collocazione=lambda do |section,collocation|
      sql=%Q{select specification as id from clavis.item where section='#{section}'
      and collocation='#{collocation}' and specification!='';}
      pg=ActiveRecord::Base.connection.execute(sql)
      keys={}
      pg.each do |r|
        id=r['id'].to_i
        next if id==0
        keys[id]=true
      end
      k=keys.keys
      return "#{section} [collocazione errata: \"#{collocation}\"]\n" if k.size==0
      na=(k.min..k.max).to_a
      mancanti=na-k
      msg= mancanti.size==0 ? '[completo]' : " - mancano #{mancanti.size} numeri: #{mancanti.sort.join(', ')}"
      return "#{section}.#{collocation} (#{k.min}-#{k.max})#{msg}\n"
    end

    ['SERA.ARA','BCT09','BCT10','BCT11','BCT12','BCT13','BCT14','BCT15','BCT16','BCTA'].each do |s|
      outfile="/usr/local/www/html/mn/00_#{s}_missing_numbers.txt"
      puts outfile
      File.delete(outfile) if File.exists?(outfile)
      fd=File.open(outfile, "w")
      # sql="set statement_timeout=0;select distinct trim(collocation) as c from clavis.item where collocation!='' and section='BCT12' order by trim(collocation)"
      # Corretto 29 agosto 2013:
      sql="set statement_timeout=0;select distinct trim(collocation) as c from clavis.item where collocation!='' and section='#{s}' order by trim(collocation)"
      pg=ActiveRecord::Base.connection.execute(sql)
      pg.each do |r|
        fd.write(buchi_collocazione.call(s,r['c']))
        fd.flush
      end
      fd.close
    end
  end

  # trova_numeri.call('CSP',677,1)
  # exit

  # trova_numeri.call('V',2,280000)
  # exit

  # trova_periodici_mancanti
  missing_numbers

  # trova_numeri.call('V',2,280000)
  # exit

  trova_numeri.call('01',2,280000)
  trova_numeri.call('ARA',2,1)
  trova_numeri.call('ART',2,1)
  trova_numeri.call('AUT',2,1)
  trova_numeri.call('BOS',2,1)
  trova_numeri.call('CIO',2,1)
  trova_numeri.call('DL',2,1)
  trova_numeri.call('GIO',2,5001)
  trova_numeri.call('MIS',2,1)
  trova_numeri.call('MRN',2,1)
  trova_numeri.call('P',2,30000)
  trova_numeri.call('PIE',2,1)
  trova_numeri.call('RAG',2,1)
  trova_numeri.call('TAT',2,1)

  trova_numeri.call('75',3,1)
  # trova_numeri.call('CIV',3,1)
  trova_numeri.call('D',3,1)
  # trova_numeri.call('M',3,1) ; 

  # http://bctdoc.comperio.it/issues/240
  trova_numeri.call('M',3,54800)

  trova_numeri.call('MA',3,1)
  trova_numeri.call('MP',3,1)
  trova_numeri.call('PRA',3,1)
  trova_numeri.call('PRE',3,1)
  
  trova_numeri.call('BEL',4,1)

  # trova_numeri.call('TP',5,280000)
  trova_numeri.call('ARQ',5,1)

  # trova_numeri.call('TP',6,280000)
  trova_numeri.call('ALO',6,1)

  # trova_numeri.call('TP',7,280000)
  trova_numeri.call('MAN',7,1)

  trova_numeri.call('MAR',8,1)
  trova_numeri.call('STR',9,1)
  trova_numeri.call('TA',10,280000)
  trova_numeri.call('TB',11,280000)
  # trova_numeri.call('TC',12,280000) ; # rimosso il 17 giugno 2013
  trova_numeri.call('TD',13,280000)
  trova_numeri.call('TE',14,280000)
  trova_numeri.call('TF',15,280000)
  trova_numeri.call('TH',16,280000)
  trova_numeri.call('TI',17,280000)
  trova_numeri.call('TL',18,280000)
  trova_numeri.call('TM',19,280000)
  trova_numeri.call('TN',20,280000)

  trova_numeri.call('FA',21,1)
  trova_numeri.call('TO',21,280000)
  trova_numeri.call('FEM',21,1)

  trova_numeri.call('TP',22,280000)
  trova_numeri.call('NPL',22,1)
  trova_numeri.call('SGB',22,1)

  # trova_numeri.call('TR',22,280000)
  # trova_numeri.call('MAN',22,1)
  #trova_numeri.call('OSP',22,1)

  trova_numeri.call('TR',23,1)
  trova_numeri.call('TS',24,280000)
  trova_numeri.call('TT',25,280000)
  trova_numeri.call('TU',26,280000)

  # Tolto su richiesta di Pat il 26 novembre 2012
  # trova_numeri.call('TG',27,280000)
  trova_numeri.call('TV',27,280000)

  # trova_numeri.call('CI',28,1) ; # rimosso il 17 giugno 2013

  trova_numeri.call('TZ',29,280000)
  #trova_numeri.call('NVNA',29,1)
  #trova_numeri.call('NVNB',29,1)
  #trova_numeri.call('NVNC',29,1)
  #trova_numeri.call('NVNT',29,1)
  #trova_numeri.call('NVCDMP',29,1)
  #trova_numeri.call('NVCDNA',29,1)
  #trova_numeri.call('NVCDNB',29,1)
  #trova_numeri.call('NVCDNT',29,1)

  # trova_numeri.call('TG',30,280000) ; # rimosso il 17 giugno 2013

  trova_numeri.call('NN',31,1)
  trova_numeri.call('FOM',31,1)
  trova_numeri.call('FPS',31,1)
  trova_numeri.call('NAD',31,1)
  trova_numeri.call('RGC',31,1)
  trova_numeri.call('XIV',31,1)

  trova_numeri.call('UJ',32,1)

  trova_numeri.call('V',33,1)
  trova_numeri.call('U8',33,1)

  trova_numeri.call('GIN',496,1)

  # http://bctdoc.comperio.it/issues/191
  trova_numeri.call('CSP',677,1)

  # Trova bid duplicati
  cmd=%Q{/usr/local/bin/psql -H -o /usr/local/www/html/mn/00_bid_duplicati.html -q -d informhop informhop --command "select bid,count(*) from clavis.manifestation where bid notnull group by bid having count(*)>1 order by bid;"}
  puts cmd
  Kernel.system(cmd)


  # Trova inventari duplicati (esclude i periodici e l'inventario 0 (zero)
  sql=%Q{select inventory_serie_id,inventory_number,count(*) from clavis.item where issue_id isnull and inventory_serie_id notnull  and inventory_number != 0 group by owner_library_id,inventory_serie_id,inventory_number having count(*)>1 order by inventory_serie_id,inventory_number}
  cmd=%Q{/usr/local/bin/psql -H -o /usr/local/www/html/mn/00_inventari_duplicati.html -q -d informhop informhop --command "#{sql}"}
  puts cmd
  Kernel.system(cmd)

  # Aggiunto 17 maggio 2012 : auth_opere_blanks
  cmd=%Q{/usr/local/bin/psql -H -q -d informhop informhop --command "select '<a href=http://tobi.selfip.info/titles/' || m.bid || '>' || m.bid || '</a>' as link_a_tobi, a.authority_id,l.manifestation_id,m.title from clavis.authority a left join clavis.l_authority_manifestation l using(authority_id) left join clavis.manifestation m using(manifestation_id) where authority_type='O' and a.sort_text='' order by a.authority_id,m.manifestation_id;" | /usr/bin/sed s/\"&lt;\"/\"<\"/g | /usr/bin/sed s/\"&gt;\"/\">\"/g | /usr/bin/sed s/\"&quot;\"/\\"/g > /usr/local/www/html/mn/00_auth_opere_blanks.html}
  puts cmd
  Kernel.system(cmd)


  # Trova autori personali duplicati
  # cmd=%Q{/usr/local/bin/psql -H -o /usr/local/www/html/mn/00_authority_forse_duplicati.html -q -d informhop informhop --command "select replace(full_text,' ' ,''),count(*) from clavis.authority where authority_type='P' and full_text!='' group by replace(full_text,' ' ,'') having count(*)>1 order by count(*) desc limit 100;"}
  cmd=%Q{/usr/local/bin/psql -H -o /usr/local/www/html/mn/00_authority_forse_duplicati.html -q -d informhop informhop --command "select full_text,count(*) from clavis.authority where authority_type='P' and full_text!='' group by full_text having count(*)>1 order by count(*) desc, full_text;"}
  puts cmd
  Kernel.system(cmd)

  cmd=%Q{/usr/local/bin/psql -H -q -d informhop informhop --command "select '<a href=http://sbct.comperio.it/index.php?page=Catalog.AuthorityViewPage&id=' || authority_id || '>' || full_text || '</a>',term_resource,created_by,date_created::date from clavis.authority where full_text in (select full_text from clavis.authority  where authority_type='P' and full_text!='' group by full_text having count(*)>1) order by full_text,term_resource;" | /usr/bin/sed s/\"&lt;\"/\"<\"/g | /usr/bin/sed s/\"&gt;\"/\">\"/g | /usr/bin/sed s/\"&quot;\"/\\"/g > /usr/local/www/html/mn/00_autori_dup_con_vid.html}
  puts cmd
  Kernel.system(cmd)

  # Aggiunta del 26 marzo 2012: barcodes errati
  # cmd=%Q{/usr/local/bin/psql -H -q -d informhop informhop --command "set search_path=clavis;set statement_timeout=0;select l.shortlabel as biblioteca, barcode,'<a href=http://sbct.comperio.it/index.php?page=Catalog.ItemInsertPage&id=' || item_id || '>' || item_id || '</a>' as item_id from item i join library l on(l.library_id=i.owner_library_id) where barcode like 'B%' and 'B' || item_id != barcode order by owner_library_id,i.item_id" | /usr/bin/sed s/\"&lt;\"/\"<\"/g | /usr/bin/sed s/\"&gt;\"/\">\"/g | /usr/bin/sed s/\"&quot;\"/\\"/g > /usr/local/www/html/barcodes_errati.html}
  # Modificato 2 aprile 2012, includo solo i barcodes numerici ("B+numero")
  extracond="isdigits(substr(barcode,2,12)) and abs(item_id-substr(barcode,2,12)::integer)<10"
  # extracond="isdigits(substr(barcode,2,12))"
  cmd=%Q{/usr/local/bin/psql -H -q -d informhop informhop --command "set search_path=clavis;set statement_timeout=0;select l.shortlabel as biblioteca, barcode,'<a href=http://sbct.comperio.it/index.php?page=Catalog.ItemInsertPage&id=' || item_id || '>' || item_id || '</a>' as item_id from item i join library l on(l.library_id=i.owner_library_id) where barcode like 'B%' and 'B' || item_id != barcode AND #{extracond} order by owner_library_id,i.item_id" | /usr/bin/sed s/\"&lt;\"/\"<\"/g | /usr/bin/sed s/\"&gt;\"/\">\"/g | /usr/bin/sed s/\"&quot;\"/\\"/g > /usr/local/www/html/barcodes_errati.html}
  puts cmd
  Kernel.system(cmd)


  # Aggiunta del 2 aprile 2012: barcodes duplicati
  cond="barcode in (select barcode from item where barcode notnull group by barcode having count(*)>1)"
  outfile="/usr/local/www/html/mn/00_barcodes_duplicati.html"
  cmd=%Q{/usr/local/bin/psql -H -q -d informhop informhop --command "set search_path=clavis;set statement_timeout=0;select l.shortlabel as biblioteca, barcode, i.date_created,'<a href=http://sbct.comperio.it/index.php?page=Catalog.ItemInsertPage&id=' || item_id || '>' || item_id || '</a>' as item_id from item i join library l on(l.library_id=i.owner_library_id) where #{cond} order by i.date_created desc,i.item_id" | /usr/bin/sed s/\"&lt;\"/\"<\"/g | /usr/bin/sed s/\"&gt;\"/\">\"/g | /usr/bin/sed s/\"&quot;\"/\\"/g > #{outfile}}
  puts cmd
  Kernel.system(cmd)
  data=File.read(outfile)
  quando=Time.now
  data=%Q{<html><head><meta http-equiv="content-type" content="text/html; charset=UTF-8"/><title>Item barcodes duplicati></title></head><body><div><p>Data rilevazione: #{quando}<br/>Item barcodes duplicati, ordinamento per data di creazione, discendente</p>#{data}</div></body></html>}
  fd=File.open(outfile,'w')
  fd.write(data)
  fd.close

  # Aggiunta dell'8 aprile 2012: archivia_html
  cmd=%Q{/usr/bin/tar -C /usr/local/www/html -cvjf /home/midolo/ProgettiCivica/IntraVedo/html/costellazione_clavis.tar.bz2 mn}
  Kernel.system(cmd)

end
