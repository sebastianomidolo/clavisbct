# -*- coding: utf-8 -*-
# -*- mode: ruby;-*-

desc 'Missing descriptions'

require 'open-uri'

task :sync_page => :environment do


  def dettagli_evento(sourcefile)
    
  end

  def write_html_page(xml, destfile)
    puts "scrivo in #{destfile}"
    outfd=File.open(destfile, 'w')
    templ=%Q{<img src="img/beatle.jpg" alt="Logo dell'attività" width="140" height="100" />
<h3>
<a href="http://www.comune.torino.it/cultura/biblioteche/agenda/servizionline/memento/include.php?urlDest=http://www.comune.torino.it/cultura/biblioteche/agenda/REPLACE_ME_PLEASE">TITLE_HERE</a>
</h3>
<p>DESCRIZIONE_APPUNTAMENTO<br/>
<strong>EXTRAINFO</strong>.</p>}

    xml.root.xpath("channel/item").each do |e|
      title=e.xpath('title').text
      link=e.xpath('link').text
      descrizione=e.xpath('description').text
      details=get_event_details(link)
      if details.nil?
        puts "Errore lettura dettagli: #{link}"
        next
      end
      link=link.gsub("&","&amp;")
      link=link.split('?').last
      puts title

      placeinfo=details.css("div[class='infoAppuntamento']").css("span[class='dettLuogo']")
      descrinfo=details.css("div[class='descrizioneAppuntamento']").css("p")


      extrainfo="#{placeinfo.xpath("strong")[1].next.text.sub(/^: /,'')}"
      extrainfo+=" - #{placeinfo.xpath("strong")[2].next.text.sub(/^: /,'')}"

      # extrainfo=placeinfo.search
      

      r=String.new(templ)
      r.sub!('REPLACE_ME_PLEASE', "&amp;#{link}")
      r.sub!('TITLE_HERE', title)
      r.sub!('DESCRIZIONE_APPUNTAMENTO', descrizione)
      r.sub!('EXTRAINFO', extrainfo)
      outfd.write(r)
    end
    outfd.close
  end


  def get_event_details(link)
    if (/&uid=(.*)/ =~ link).nil?
      puts "Errore link: #{link}"
      return nil
    end
    fname=File.join("/tmp", $1)
    if !File.exists?(fname)
      puts "scarico #{link}"
      doc = Nokogiri::HTML(open(link))
      fd=File.open(fname, "w")
      fd.write(doc.to_s)
      fd.close
    else
      doc = Nokogiri::HTML(open(fname))
    end
    doc
  end

  url="http://www.comune.torino.it/servizionline/memento/user.php?context=rss&action=rss&currDate=2013-03-27&refCanale=92&refLanguage=it&refProgetto=4"

  url="http://www.comune.torino.it/servizionline/memento/user.php?context=rss&action=rss&daDataPag=11/03/2013&aDataPag=18/03/2013&refCanale=92&refLanguage=it&refProgetto=4"
  xml = Nokogiri::XML(open(url))
  fd=File.open("/tmp/test.xml", "w")
  fd.write(xml.to_s)
  fd.close
  # xml=Nokogiri::XML(File.open("/tmp/test.xml"))

  write_html_page(xml, "/tmp/indexfile.html")

end
