# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake subjects_import
# In production:
# RAILS_ENV=production  rake subjects_import

desc 'Importazione soggettario BCT'

task :subjects_import => :environment do

  def read_from_xml(filepath, dbname, username)
    puts "leggo #{filepath}"
    xml = Nokogiri::XML(open(filepath))
    # puts xml.inspect
    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("import",tempdir)
    tempfile=tf.path
    puts tempfile
    fdout=File.open(tempfile,'w')
    fdout.write("\\pset tuples_only t\n\\pset border 0\n\\pset pager f\nTRUNCATE public.subjects;\nSELECT setval('public.subjects_id_seq', 1);\nTRUNCATE public.subject_subject;\nCOPY public.subjects (inbct,heading,clavis_subject_class,scope_note) FROM stdin;\n")
    items=Hash.new
    notes=Hash.new
    xml.root.xpath("subject").each do |e|
      heading=e.xpath('heading').text
      items[heading]=true
      scope_note=e.xpath('descr').text
      if !scope_note.blank?
        notes[heading]=scope_note.gsub("\n", " ").squish if notes[heading].blank?
      end
      # puts "====> #{heading} <===="
      e.xpath("seealso/seealso").each do |t|
        voce=t.text.gsub(/\. /, ' - ')
        voce.strip!
        items[voce]=true
      end
      e.xpath("bt/bt").each do |t|
        voce=t.text.sub(/^@es /,'')
        voce.gsub!(/\. /, ' - ')
        # puts "voce: #{voce}"
        voce.strip!
        items[voce]=true
      end
      e.xpath("see/see").each do |t|
        voce=t.text
        voce.strip!
        items[voce]=true
      end
      e.xpath("headings/heading").each do |t|
        voce="#{heading} - #{t.text}"
        voce.strip!
        items[voce]=true
      end
    end

    items.keys.each do |v|
      scope_note=notes[v].blank? ? '\\N' : notes[v]
      fdout.write("true\t#{v}\tFI\t#{scope_note}\n")
    end
    fdout.write("\\.\n")

    fdout.write("DROP TABLE public.temp_subjects;CREATE TABLE public.temp_subjects (s1 text, s2 text, linktype varchar(20), seq integer);\n")
    fdout.write("COPY public.temp_subjects (s1,s2,linktype,seq) FROM stdin;\n")
    xml.root.xpath("subject").each do |e|
      heading=e.xpath('heading').text
      heading.strip!
      seq=0
      e.xpath("seealso/seealso").each do |t|
        seq+=1
        voce=t.text.gsub(/\. /, ' - ')
        voce.strip!
        fdout.write("#{heading}\t#{voce}\tsa\t#{seq}\n")
      end
      seq=0
      e.xpath("bt/bt").each do |t|
        seq+=1
        voce=t.text.sub(/^es\. /,'')
        voce=voce.gsub(/\. /, ' - ')
        voce.strip!
        fdout.write("#{heading}\t#{voce}\tbt\t#{seq}\n")
      end
      seq=0
      e.xpath("see/see").each do |t|
        seq+=1
        voce=t.text
        voce.strip!
        fdout.write("#{heading}\t#{voce}\tsee\t#{seq}\n")
      end
      seq=0
      e.xpath("headings/heading").each do |t|
        seq+=1
        voce=t.text
        voce.strip!
        if voce.blank?
          puts "Errore: #{heading} (t=#{t})"
        else
          fdout.write("#{heading}\t#{heading} - #{voce}\tsub\t#{seq}\n")
        end
      end
    end
    fdout.write("\\.\n")

    delsql=%Q{delete from temp_subjects as ts
 using(
select x.s1,x.s2,x.linktype,x.seq,x.row_number as x_row_number,y.row_number as y_row_number from
  (select row_number() over (partition by s1,s2,linktype), s1,s2,linktype,seq from temp_subjects) as x
    join
  (select row_number() over (partition by s1,s2,linktype), s1,s2,linktype,seq from temp_subjects) as y
    using(s1,s2,linktype)
  where y.row_number>1 and x.row_number=1 order by x.s1,x.s2,x.linktype,x.seq) z
  where ts.s1=z.s1 and ts.s2=z.s2 and ts.linktype=z.linktype and ts.seq=z.seq;
  }

    # Non eseguo questo sql
    sql=%Q{#{delsql}#{delsql}
INSERT INTO public.subject_subject(s1_id,s2_id,linktype,seq)
  SELECT DISTINCT s1.id,s2.id,ts.linktype,ts.seq FROM public.subjects s1
     JOIN temp_subjects ts ON(ts.s1=s1.heading) JOIN subjects s2 ON(ts.s2=s2.heading);\n}

    sql="\\pset pager t\n"
    fdout.write(sql)
    fdout.close
    cmd="/bin/cp #{tempfile} /tmp/testfile.sql"
    puts cmd
    Kernel.system(cmd)
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{tempfile}"
    puts cmd
    Kernel.system(cmd)

    tf.close(true)
  end

  def esamina_voce(source)
    equiv={
      '-' => :subitem,
      'v.a.' => :seealso,
      'v.a' => :seealso,
      '*'   => :see,
      '@bt'  => :bt,
    }
    tags=equiv.keys
    tags << 'descr'
    source += "\n END"

    lines=source.split("\n")
    heading=lines.shift
    # puts "heading: #{heading}"
    prec_tag=tag=nil
    res=Hash.new
    res[:heading] = heading.strip
    h=Hash.new
    lines.each do |l|
      l.gsub!(/^ (.?)$/, '')
      # puts "line: #{l}"
      if /^ / =~ l
        # puts "continua (tag=#{tag}): #{l}"
        if tag.nil?
          tag = 'descr'
          h[tag]=[]
          h[tag] << l.strip
        else
          h[tag] << l.strip if tags.include?(tag)          
        end

      else
        if h[tag].class==Array
          tg = equiv[tag].nil? ? tag : equiv[tag]
          # puts "tag #{tag} (#{tg} - size: #{h[tag].size}) => #{h[tag].inspect}"

          if tg == :subitem
            res[tg] = [] if res[tg].nil?
            res[tg] << h[tag].split('-').first
            # puts "res.class: #{res.class} - #{res.inspect}"
          else
            if h[tag].size==1
              content = h[tag].join(' ').split("; ")
            else
              content= h[tag]
              content = content.join(' ') if tag=='descr'
              if tg == :seealso or tg == :bt
                content = content.join(' ').split('; ')
              end
            end
            res[tg] = content
          end
        end
        row=l.split
        tag=row.shift
        if tags.include?(tag)
          # puts "equiv.keys: #{equiv.keys}"
          # puts "nuovo (tag #{tag}): #{l}"
          h[tag] = []
          h[tag] << row.join(' ').strip
          prec_tag=tag
        end
      end
    end
    res.delete_if {|k| k.nil?}
  end

  def leggi_file_principale(fname, xmlfile)
    utfname="#{fname}.utf8"
    puts fname
    cmd="/usr/bin/iconv -f latin1 -t utf8 #{fname} > #{utfname}"
    Kernel.system(cmd)
    data=File.read(utfname)
    data.gsub!('**','@bt')
    data.gsub!('es.','@es')
    puts data.size
    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("import",tempdir)
    tempfile=tf.path
    puts tempfile
    fdout=File.open(tempfile,'w')
    fdout.write("TRUNCATE public.subjects;COPY public.subjects (heading) FROM stdin;\n")
    data.gsub!("\t",'      ');
    data.gsub!("&lt;",'<');
    data.gsub!("&gt;",'>');

    records=data.split('@so ')
    records.shift
    puts "trovati #{records.size} soggetti"
    cnt=0

    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("subjects",tempdir)
    tempfile=tf.path
    puts "tempfile: #{tempfile}"
    fdout=File.open(tempfile,'w')
    fdout.write(%Q{<?xml version="1.0" encoding="UTF-8"?>\n<soggettario>\n})
    records.each do |r|
      subject=esamina_voce(r)

      if !subject[:subitem].nil?
        subject[:headings]=[]
        subject[:subitem].each do |s|
          s.each do |item|
            item.strip!
            next if item.blank?
            if (/^-/ =~ item)
              subject[:headings] << "#{s.first} - #{item.sub(/^- */,'')}"
            else
              subject[:headings] << item
            end
          end
        end
        subject.delete :subitem
      end
      fdout.write(subject.to_xml(:root=>:subject, :skip_instruct=>true, :indent=>1))
      cnt+=1
      # break if cnt>10
    end
    fdout.write("</soggettario>\n")
    fdout.close
    cmd="/bin/cp #{tempfile} #{xmlfile}"
    puts cmd
    Kernel.system(cmd)
    tf.close(true)
  end
  
  def leggi_soggettario(sourcedir, xmlfile)
    leggi_file_principale(File.join(sourcedir,'so.txt'), xmlfile)
    # leggi_file_principale(File.join(sourcedir,'letteratura_musicale.txt'), xmlfile)
    # leggi_file_principale('/tmp/so_tiny.txt', xmlfile)
  end

  def crossreferences(dbname,username)
    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("import",tempdir)
    tempfile=tf.path
    fdout=File.open(tempfile,'w')
    fdout.write(%Q{\\pset pager f
BEGIN; DROP TABLE temp_links; COMMIT;
CREATE TABLE temp_links AS
SELECT NULL::integer as source_id,NULL::integer AS target_id, NULL::integer AS linked_id,linktype,s1,s2,
  regexp_replace(s2,'(.*)(@es )(.*)','\\3') as heading, 
  regexp_replace(s2,'(.*)(@es )(.*)','\\1') as linknote, seq
  from temp_subjects;
UPDATE temp_links SET linknote = NULL WHERE linknote=heading;
UPDATE temp_links SET linknote = NULL WHERE linknote='';

BEGIN; DROP TABLE temp_intestazioni_mancanti; COMMIT;
CREATE TABLE temp_intestazioni_mancanti AS
 (SELECT DISTINCT heading FROM temp_links tl LEFT JOIN subjects s USING(heading) WHERE s.heading IS NULL);

SELECT 'Inserisco le intestazioni per soggetto mancanti' AS "Messaggio";
INSERT INTO public.subjects (inbct,heading,clavis_subject_class)
  (SELECT true,trim(heading),'CIV_X' FROM temp_intestazioni_mancanti);

SELECT 'Aggiorno temp_links (source_id)' AS "Messaggio";
UPDATE temp_links AS tl SET source_id=x.id
FROM
  (SELECT s.id,s.heading FROM temp_links tl join subjects s on(s.heading=tl.s2)) as x
 WHERE tl.s2=x.heading AND tl.source_id IS NULL;

SELECT 'Aggiorno temp_links (linked_id)' AS "Messaggio";
UPDATE temp_links AS tl SET linked_id=x.id
FROM
  (SELECT s.id,s.heading FROM temp_links tl JOIN subjects s ON(s.heading=tl.s1)) as x
 WHERE tl.s1=x.heading AND tl.linked_id IS NULL;

SELECT 'Aggiorno temp_links (target_id)' AS "Messaggio";
UPDATE temp_links AS tl SET target_id=x.id
FROM
  (SELECT s.id,s.heading FROM temp_links tl JOIN subjects s USING(heading)) AS x
 WHERE tl.heading=x.heading AND tl.target_id IS NULL;


SELECT 'Inserisco legami di base tra soggetti' AS "Messaggio";
INSERT INTO subject_subject (s1_id, s2_id, linktype, seq)
(SELECT linked_id, target_id, linktype, seq FROM temp_links WHERE source_id=target_id);
DELETE FROM temp_links WHERE source_id=target_id;

SELECT 'Inserisco legami vedi anche tra soggetti' AS "Messaggio";
INSERT INTO subject_subject (s1_id, s2_id, linktype, seq, linknote)
(SELECT linked_id, target_id, linktype, seq, linknote FROM temp_links
   WHERE source_id!=target_id AND linktype='sa' AND NOT linknote ~ '\\[');
DELETE FROM temp_links WHERE source_id!=target_id AND linktype='sa' AND NOT linknote ~ '\\[';

SELECT 'Inserisco legami bt tra soggetti' AS "Messaggio";
INSERT INTO subject_subject (s1_id, s2_id, linktype, seq, linknote)
(SELECT linked_id, target_id, linktype, seq, linknote FROM temp_links
   WHERE source_id!=target_id AND linktype='bt');
DELETE FROM temp_links WHERE source_id!=target_id AND linktype='bt';

SELECT 'Inserisco legami bt @es tra soggetti' AS "Messaggio";
INSERT INTO subject_subject (s1_id, s2_id, linktype, seq)
(SELECT linked_id, target_id, linktype, seq FROM temp_links
   WHERE source_id IS NULL AND linktype='bt' AND s2 ~ '@es' AND linknote IS NULL);
/*
INSERT INTO subject_subject (s2_id, s1_id, linktype, seq, linknote)
(SELECT linked_id, target_id, 'sa', seq, '-' FROM temp_links
   WHERE source_id IS NULL AND linktype='bt' AND s2 ~ '@es' AND linknote IS NULL);
*/
DELETE FROM temp_links WHERE source_id IS NULL AND linktype='bt' AND s2 ~ '@es' AND linknote IS NULL;

INSERT INTO subject_subject (s1_id, s2_id, linktype, seq, linknote)
(select linked_id, target_id, linktype, seq, linknote from temp_links
   where linktype = 'sub' and linked_id is not null and target_id is not null);

SELECT 'Aggiorno subjects (clavis_authority_id)' AS "Messaggio";
UPDATE subjects AS s SET clavis_authority_id = c.authority_id
 FROM
  (SELECT authority_id,full_text FROM clavis.authority WHERE authority_type ='S') AS c
    WHERE s.clavis_authority_id IS NULL
     AND heading=full_text;

SELECT 'Inserisco in subjects da clavis.authorities di tipo S' AS "Messaggio";
INSERT INTO subjects (clavis_subject_class,heading,clavis_authority_id)
 (SELECT trim(ca.subject_class),ca.full_text,ca.authority_id FROM clavis.l_subject ls
    JOIN clavis.authority ca ON(ls.subject_id=ca.authority_id)
    LEFT JOIN subjects s ON(s.heading=ca.full_text AND s.clavis_subject_class=ca.subject_class
      AND s.clavis_authority_id=ca.authority_id)
   WHERE s.heading IS NULL AND ca.authority_type='S' AND ls.position=0 AND ca.subject_class is not null);

\\pset pager t
})
    fdout.close
    cmd="/bin/cp #{tempfile} /tmp/crossfile.sql"
    puts cmd
    Kernel.system(cmd)
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{tempfile}"
    puts cmd
    Kernel.system(cmd)
    tf.close(true)
  end



  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]

  # crossreferences(dbname,username)
  # exit

  xmlfile="/tmp/subxml.xml"
  File.delete(xmlfile) if File.exists?(xmlfile)
  if !File.exists?(xmlfile)
    # leggi_soggettario(config[Rails.env]["subjects_source"], dbname, username, xmlfile)
    leggi_soggettario(config[Rails.env]["subjects_source"], xmlfile)
  end
  # exit
  read_from_xml(xmlfile, dbname, username)
  crossreferences(dbname,username)
end
