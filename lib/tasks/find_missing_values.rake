
desc 'Trova valori mancanti in una sequenza di numeri in tabella'
task :find_missing_values => :environment do

  trova_numeri=lambda do |serie,library,min_filter|
    table='clavis.item'
    number="inventory_number"
    conn=ClavisItem.connection
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
    cmd="/usr/bin/psql -q -d clavisbct_development informhop  -f #{file}"
    # puts cmd
    Kernel.system(cmd)

    sql=%Q{select id from public.sequenza_numeri where id not in
 (select #{number} from #{table} where #{conditions}) order by id;}
    puts sql

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

    ['SERA.ARA','BCT09','BCT10','BCT11','BCT12','BCT13','BCT14','BCT15','BCT16','BCT17','BCT18','BCTA'].each do |s|
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


  def trova_salti_dvd
    sql=%Q{
     create temp table buchi_dvd as select item_id,collocation,
       split_part(collocation, '.', 1) AS sigla, 
       split_part(replace(collocation, '/', '.'), '.', 2) AS catena
     from clavis.item
     where collocation like 'DVD.%' and owner_library_id=2;
     delete from buchi_dvd  where catena ~* '[a-z]';
     alter table buchi_dvd alter COLUMN catena type integer using catena::integer;
     with ids as (select catena from generate_series(1,(select max(catena) from buchi_dvd)) as catena) select catena from ids left join buchi_dvd b using(catena) where b.catena is null;}
    cmd=%Q{/usr/bin/psql -H -o /usr/local/www/html/mn/02_Centrale_DVD_buchi_collocazione.html -q -d clavisbct_development informhop --command "#{sql}"}
    cmd.gsub!("\n", ' ')
    puts cmd
    Kernel.system(cmd)
  end
  trova_salti_dvd

  # trova_numeri.call('V',2,280000)
  # exit

  # trova_numeri.call('01',2,280000)
  # exit

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

  # Trova bid duplicati (18 ottobre 2016: spostato in ClavisManifestationsController#bid_duplicati)
  # cmd=%Q{/usr/bin/psql -H -o /usr/local/www/html/mn/00_bid_duplicati.html -q -d clavisbct_development informhop --command "select bid,count(*) from clavis.manifestation where bid notnull group by bid having count(*)>1 order by bid;"}
  # puts cmd
  # Kernel.system(cmd)


  # Trova inventari duplicati (esclude i periodici e l'inventario 0 (zero)
  sql=%Q{select inventory_serie_id,inventory_number,count(*) from clavis.item where issue_id isnull and inventory_serie_id notnull  and inventory_number != 0 group by owner_library_id,inventory_serie_id,inventory_number having count(*)>1 order by inventory_serie_id,inventory_number}
  cmd=%Q{/usr/bin/psql -H -o /usr/local/www/html/mn/00_inventari_duplicati.html -q -d clavisbct_development informhop --command "#{sql}"}
  puts cmd
  Kernel.system(cmd)


  # Trova autori personali duplicati
  # cmd=%Q{/usr/bin/psql -H -o /usr/local/www/html/mn/00_authority_forse_duplicati.html -q -d clavisbct_development informhop --command "select replace(full_text,' ' ,''),count(*) from clavis.authority where authority_type='P' and full_text!='' group by replace(full_text,' ' ,'') having count(*)>1 order by count(*) desc limit 100;"}
  cmd=%Q{/usr/bin/psql -H -o /usr/local/www/html/mn/00_authority_forse_duplicati.html -q -d clavisbct_development informhop --command "select full_text,count(*) from clavis.authority where authority_type='P' and full_text!='' group by full_text having count(*)>1 order by count(*) desc, full_text;"}
  puts cmd
  Kernel.system(cmd)

  cmd=%Q{/usr/bin/psql -H -o /usr/local/www/html/mn/00_max_inventari.html -q -d clavisbct_development informhop --command "select cl.label as biblioteca,max(inventory_number) as max_inventario from clavis.item ci join clavis.library cl on(ci.owner_library_id=cl.library_id) where ci.home_library_id != -1 AND cl.library_internal='1' AND ci.manifestation_id>0 group by (cl.label) order by cl.label;"}
  puts cmd
  Kernel.system(cmd)
end
