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
    fdout.write("TRUNCATE public.subjects;\nSELECT setval('public.subjects_id_seq', 1);\nTRUNCATE public.subject_subject;\nCOPY public.subjects (heading) FROM stdin;\n")
    items=Hash.new
    xml.root.xpath("subject").each do |e|
      heading=e.xpath('heading').text
      # fdout.write("#{heading}\n")
      items[heading]=true
      # puts "====> #{heading} <===="
      e.xpath("seealso/seealso").each do |t|
        voce=t.text
        items[voce]=true
        # fdout.write("#{voce}\n")
        # puts "vedi anche #{voce}"
      end
    end
    items.keys.each do |v|
      fdout.write("#{v}\n")
    end
    fdout.write("\\.\n")

    fdout.write("DROP TABLE public.temp_subjects;CREATE TABLE public.temp_subjects (s1 text, s2 text, linktype varchar(20));\n")
    fdout.write("COPY public.temp_subjects (s1,s2,linktype) FROM stdin;\n")
    xml.root.xpath("subject").each do |e|
      heading=e.xpath('heading').text
      e.xpath("seealso/seealso").each do |t|
        voce=t.text
        fdout.write("#{heading}\t#{voce}\tsa\n")
      end
      e.xpath("bt/bt").each do |t|
        voce=t.text
        fdout.write("#{heading}\t#{voce}\tbt\n")
      end
    end
    fdout.write("\\.\n")

    sql=%Q{INSERT INTO public.subject_subject(s1_id,s2_id,linktype) SELECT DISTINCT s1.id,s2.id,ts.linktype FROM public.subjects s1 JOIN temp_subjects ts ON(ts.s1=s1.heading) JOIN subjects s2 ON(ts.s2=s2.heading);
    }
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
      '**'  => :bt,
    }
    tags=equiv.keys
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
          if h[tag].size==1
            content = h[tag].join(' ').split("; ")
          else
            content= h[tag]
            content = content.join(' ') if tag=='descr'
            if tg == :seealso
              content = content.join(' ').split('; ')
            end
          end
          res[tg] = content
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
      # puts subject.inspect
      fdout.write(subject.to_xml(:root=>:subject, :skip_instruct=>true, :indent=>1))
      # fdout.write("#{subject.to_yaml}\n")
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
  end

  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  xmlfile="/tmp/subxml.xml"
  File.delete(xmlfile) if File.exists?(xmlfile)
  if !File.exists?(xmlfile)
    # leggi_soggettario(config[Rails.env]["subjects_source"], dbname, username, xmlfile)
    leggi_soggettario(config[Rails.env]["subjects_source"], xmlfile)
  end
  read_from_xml(xmlfile, dbname, username)
end
