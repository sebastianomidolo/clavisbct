# -*- mode: ruby;-*-

desc 'Importazione Nuovo soggettario BNCF'


def importa_bncf_xml(cnt, fname, categoria, fdout)
  # fname='/home/seb/bncf/prova.xml'
  f = File.open(fname)
  doc = Nokogiri::XML(f) do |config|
    config.strict.nonet
  end
  doc.xpath('//rdf:Description ').each do |e|
    cnt+=1
    url=e.attributes['about'].value
    id = url.split('/').last
    rdftype=e.xpath('rdf:type').first.attributes['resource'].value.split('#').last
    label=e.xpath('skos:prefLabel ').first
    if label.nil?
      # puts "Non trovato label per id #{id}"
      label=e.xpath('rdfs:label').text
    else
      label=label.text
    end
    definition=e.xpath('skos:definition').first
    if definition.nil?
      definition="\\N"
    else
      definition=definition.text
    end
    fdout.write "#{cnt}\t#{categoria}\t#{id}\t#{label}\t#{rdftype}\t\\N\tprefLabel\t#{definition}\n"
    ref_id=cnt
    e.xpath('skos:altLabel ').each do |t|
      cnt+=1
      fdout.write "#{cnt}\t#{categoria}\t\\N\t#{t.text}\t#{rdftype}\t#{ref_id}\taltLabel\t\\N\n"
    end
    e.xpath('nsogi:obsoleteTerm').each do |t|
      cnt+=1
      fdout.write "#{cnt}\t#{categoria}\t\\N\t#{t.text}\t#{rdftype}\t#{ref_id}\tobsoleteTerm\t\\N\n"
    end
  end
  cnt
end

task :bncf_import => :environment do
  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]

  sourcedir="/home/seb/bncf"

  sqlfile="/tmp/bncf_import.sql"
  fdout=File.open(sqlfile,'w')
  fdout.write(%Q{DROP TABLE public.bncf_terms;CREATE TABLE public.bncf_terms (id integer primary key, bncf_id integer, category varchar(21), term varchar(128), rdftype varchar(10), parent_id integer, definition text, termtype varchar(12));\n})
  fdout.write(%Q{COPY public.bncf_terms (id, category, bncf_id, term, rdftype, parent_id, termtype, definition) FROM stdin;\n})
  entries=Dir.entries(sourcedir).delete_if {|z| ['.','..'].include?(z)}.sort
  cnt=0
  entries.each do |entry|
    file=File.join(sourcedir,entry)
    next if File.directory?(file)
    next if (entry =~ /NS-SKOS-(.*).xml/).nil?
    cnt += importa_bncf_xml(cnt,file,$1,fdout)
    # puts "file: #{file} - '#{$1}' - importati #{cnt} termini"
  end
  fdout.write("\\.\n")
  fdout.write %Q{
    create unique index bncf_terms_id_ndx on bncf_terms (id);
    create index bncf_terms_term_ndx on bncf_terms (term);
  }

end

