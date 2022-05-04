# -*- mode: ruby;-*-

desc 'Conversione tag unimarc 856 in 300 secondo indicazioni ICCU'

task :conv_856_300 => :environment do
  sql=%Q{select distinct u.manifestation_id,u.unimarc_tag,cm.unimarc from clavis.url_sbn u join clavis.manifestation cm
           using(manifestation_id) where u.unimarc_tag is not null and cm.unimarc notnull
    -- and cm.manifestation_id=968923
    order by u.manifestation_id
    ;
   }
  puts sql
  context = {ignore_whitespace_nodes: :all, compress_whitespace: :all}

  outfname = '/tmp/unimarc_update.sql'
  fd = File.open(outfname, 'w')

  conn = ActiveRecord::Base.connection
  cnt = 0
  conn.execute(sql).each do |r|
    puts "manifestation_id #{r['manifestation_id']} - tag unimarc #{r['unimarc_tag']}"
    doc=REXML::Document.new(r['unimarc'].sub(%Q{<?xml version=\"1.0\"?>},''), context)
    doc.root.elements.each do |el|
      next if !['d856','d300'].include?(el.name)
      # puts "#{el.name} => #{el.size}"
      if el.name == 'd300'
        iccu_url  = el.get_elements('sa').first.text
        next if (iccu_url =~ /^<URL>/).nil?
        # puts "iccu_url #{iccu_url}"
      else
        url  = el.get_elements('su').first.text
        nota = el.get_elements('sz').first
        nota = nota.nil? ? '' : nota.text
        # puts "url856: #{url}"
        # puts "nota: #{nota}"
        iccu_url = "<URL> #{nota.blank? ? '' : nota + ' | '}#{url}"
        puts "856=>300: #{iccu_url}"
        el.remove          
        nf = REXML::Element.new('d300', doc.root)
        nf.add_attribute('i1', ' ')
        nf.add_attribute('i2', ' ')
        sa = REXML::Element.new('sa', nf)
        sa.text = iccu_url
      end
    end
    puts "scrivo unimarc..."
    cnt += 1
    fd.write(%Q{UPDATE manifestation set unimarc = #{conn.quote(doc.to_s)} WHERE manifestation_id=#{r['manifestation_id']};\n})
    fd.write("UPDATE turbomarc_cache set dirty = '1' where manifestation_id=#{r['manifestation_id']};\n")
  end

  puts "#{cnt} record modificati, sql scritto in #{outfname}"
  fd.close
end
