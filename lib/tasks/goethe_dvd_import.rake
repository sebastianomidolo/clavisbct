# -*- mode: ruby;-*-

desc 'Importazione dati DVD Goethe Institute - da XML'

task :goethe_dvd_import => :environment do
  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]

  fdout=File.open('/tmp/goethe.sql','w')

  tables=[]
  xmldir='/home/ror/redmine/files/2014/05'
  [
   '140527154758_G146-lok.xml',
   '140527154803_G146-tit.xml',
   '140527154811_G146-aut.xml'
  ].each do |f|
    xmlfile=File.join(xmldir,f)
    puts xmlfile
    tablename="temp_goethe_import_#{f.sub('.xml','').split('-').last}"
    tables << tablename
    fdout.write("CREATE TEMP TABLE #{tablename} (xmlrec xml, id serial primary key);\n")
    fdout.write("COPY #{tablename} (xmlrec) FROM STDIN;\n");
    xml=Nokogiri::XML(open(xmlfile))
    xml.root.elements.each do |x|
      fdout.write(x.to_s.gsub("\n",''));
      fdout.write("\n");
    end
    fdout.write("\\.\n");
  end

  fdout.write("alter table temp_goethe_import_tit add column title_id text;\n")
  fdout.write("update temp_goethe_import_tit set title_id = (xpath('//record/controlfield[@tag=001]/text()',xmlrec))[1];\n")
  fdout.write("alter table temp_goethe_import_lok add column record_id text;\n")
  fdout.write("alter table temp_goethe_import_lok add column title_id text;\n")
  fdout.write("update temp_goethe_import_lok set record_id = (xpath('//record/controlfield[@tag=001]/text()',xmlrec))[1];\n")
  fdout.write("update temp_goethe_import_lok set title_id = (xpath('//record/controlfield[@tag=004]/text()',xmlrec))[1];\n")
  fdout.write("create temp table temp_goethe_import as select xmlelement(name wrapper,
  xmlelement(name bibrecord, xpath('/record/*',t.xmlrec)),
  xmlelement(name items, xpath('/record/datafield',l.xmlrec))) as xmlrec
 from temp_goethe_import_tit t join temp_goethe_import_lok l using(title_id);\n");
  tables << 'temp_goethe_import'

  fdout.write(%Q{\\pset tuples_only t
\\pset border 0
\\pset pager f
ALTER TABLE temp_goethe_import add column testo text;
UPDATE temp_goethe_import set testo=xmlrec::text;
UPDATE temp_goethe_import set testo = replace(testo,'<element>','');
UPDATE temp_goethe_import set testo = replace(testo,'</element>','');
UPDATE temp_goethe_import set xmlrec=testo::xml;
SELECT xmlcomment('inizio esportazione: ' || now());
SELECT '<root>';
SELECT testo FROM temp_goethe_import;
SELECT '</root>';
SELECT xmlcomment('fine importazione: ' || now());
})

  tables.each do |t|
    fdout.write("-- drop table #{t};\n")
  end
  fdout.close

  cmd="psql -X -q clavisbct_development informhop -f /tmp/goethe.sql > /home/sites/456.selfip.net/html/import_goethe.xml"
  puts cmd
  Kernel.system(cmd)

end
