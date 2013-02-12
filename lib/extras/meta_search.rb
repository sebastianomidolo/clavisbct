# -*- coding: utf-8 -*-
# lastmod  6 febbraio 2013 - Aggiunto modulo "polito"
# lastmod  5 febbraio 2013 - Aggiunto modulo "unito"
# lastmod  1 febbraio 2013 - Aggiunto modulo "goethe_torino"
# lastmod 31 gennaio 2013
# lastmod 28 gennaio 2013

# Example
# include MetaSearch;do_search('bct','val pellice',false,false)

require 'open-uri'

module MetaSearch

  @@opacs={
    :librinlinea=>{
      :on=>true,
      :descr=>'Catalogo Librinlinea (biblioteche piemontesi)',
      :baseurl=>'http://www.librinlinea.it',
      :query=>%q{http://www.librinlinea.it/search/public/appl/list.php?search_string=_QS_},
      :link_pattern=>'/search/public/appl/dettaglio.php?bid=__OID__',
      :oid_placeholder=>'__OID__',
      :procedures=>%q{
        def num_items(doc)
          return 0 if doc.text =~ /Non ci sono corrispondenze/
          return 1 if doc.to_html =~ Regexp.new("<h3>Descrizione bibliografica</h3>")
          x=doc.search(".num_result")
          if x.size==0
            return '?'
          else
            x.children.first.text
          end
        end
        def analizza_pagina_risultati(doc)
          parsetitle=Proc.new do |e|
            oid=e.css("h3 a").attr('href').to_s.split("=").last
            r=[]
            r << e.css("[itemprop='name']").text.strip
            r << e.css("[itemprop='author']").text.strip
            r << e.css("[itemprop='publisher']").text.strip
            r.compact!
            title=r.join(' - ')
            {:t=>title, :i=>oid}
            # %Q{<a href="#{h}">#{r.join(' - ')}</a>}
          end
          cnt=0;r={}
          doc.search('#elenco').css("div.span10").each do |e|
            cnt+=1
            r[cnt]=parsetitle.call(e)
          end
          r
        end
      }
    },
    :goethe_torino=>{
      :on=>true,
      :descr=>'Goethe-Institute di Torino',
      :baseurl=>'http://swb.bsz-bw.de/DB=2.308',
      :query=>%q{http://swb.bsz-bw.de/DB=2.308/CMD?MATCFILTER=Y&MATCSET=Y&NOSCAN=Y&ADI_BIB=m+504146&ACT=SRCHA&IKT=1016&SRT=RLV&TRM=_QS_&NOABS=Y},
      :link_pattern=>'',
      :procedures=>%q{
        def num_items(doc)
          x=doc.search('title')
          if x.size==1
            return 0 if x.text =~ Regexp.new("results/idxnotfound")
          end
          x=doc.search(".pages")
          return '?' if x.size==0
          x=x.children.first.text
          return nil if x.blank?
          x.gsub(' ', ' ').split.last
        end
        def analizza_pagina_risultati(doc)
          return {}
        end
      }
    },
    :bct=>{
      :on=>true,
      :descr=>'Biblioteche Civiche Torinesi',
      :baseurl=>'http://bct.comperio.it',
      :query=>%q{http://bct.comperio.it/opac/search/lst?q=_QS_},
      :link_pattern=>'',
      :procedures=>%q{
        def num_items(doc)
          x=doc.search("#teaser h5")
          if x.size==1
            x=x.text.split[1].to_i
          else
            '?'
          end
        end
        def analizza_pagina_risultati(doc)
          return {}
        end
      }
    },
    :unito=>{
      :on=>true,
      :descr=>"Universita' degli Studi di Torino - Catalogo unico d'Ateneo",
      :baseurl=>'http://cavour.cilea.it',
      :query=>%q{http://cavour.cilea.it/SebinaOpac/Opac?action=search&kindOfSearch=simple&startat=0&LIBERA=_QS_},
      :link_pattern=>'',
      :procedures=>%q{
        def num_items(doc)
          x=doc.search(".numerirosso")
          return 0 if x.size==0
          x=x.children.first.text
          return nil if x.blank?
          x.gsub(' ', ' ').split.last
        end
        def analizza_pagina_risultati(doc)
          return {}
        end
      }
    },
    :polito=>{
      :on=>true,
      :descr=>"Politecnico di Torino",
      :baseurl=>'http://opac.biblio.polito.it',
      :query=>%q{http://opac.biblio.polito.it/F/?func=find-e&request=_QS_&find_scan_code=FIND_WRD&adjacent=N&local_base=PTOW&filter_code_1=WLN&filter_request_1=&filter_code_2=WYR&filter_request_2=&filter_code_3=WYR&filter_request_3=&filter_code_4=WFM&filter_request_4=&filter_code_5=WBI&filter_request_5=},
      :link_pattern=>'',
      :procedures=>%q{
        def num_items(doc)
          x=doc.search('title')
          if x.size==1
            return 1 if x.text =~ /Vista completa del record/
          end
          x=doc.search("div.title")
          return 0 if x.text =~ Regexp.new('Ricerca/Scorrimento')
          return 0 if x.text =~ Regexp.new('Ricerca permutata')
          e=nil
          doc.xpath('//comment()').each {|a| e=a and break if a.text =~ /AZALAI/}
          return '?' if e.nil?
          x=e.next(); return if x.nil?
          x=x.text.strip; return if x.nil?
          return x.split.last
        end
        def analizza_pagina_risultati(doc)
          return {}
        end
      }
    },

  }

  def redirect_url(opac,query)
    return nil if opac.blank?
    opac = opac.to_sym
    target=@@opacs[opac]
    return nil if target.nil? or target[:on]==false
    if query.blank?
      target[:baseurl]
    else
      query=URI::encode(query)
      target[:query].sub('_QS_',query)
    end
  end

  def do_search(opac,query,dryrun,debug_mode=false)
    dryrun=nil if dryrun.blank?
    opac = opac.to_sym
    target=@@opacs[opac]
    return nil if target.nil? or target[:on]==false
    res={}
    res[:q]=query
    # res[:q]=URI::encode(query)

    query=URI::encode(query)
    url=target[:query].sub('_QS_',query)
    res[:url]=url

    if dryrun.nil?
      res[:dryrun]=false
      res[:list]={}
      [:descr, :baseurl, :link_pattern, :oid_placeholder].each { |k| res[k]=target[k] }
      if debug_mode
        doc = load_from_local_copy(opac)
      else
        doc = Nokogiri::HTML(open(url))
        save_local_copy(opac,doc.to_html)
      end
      eval(target[:procedures]) if !target[:procedures].blank?
      m='num_items'
      res[:num_items]=send(m, doc) if self.respond_to?(m)
      m='analizza_pagina_risultati'
      res[:list]=send(m, doc) if self.respond_to?(m)
    else
      res[:dryrun]=true
      [:descr, :baseurl].each { |k| res[k]=target[k] }
    end
    return res
  end

  def save_local_copy(opac,html)
    fn=File.join("#{Rails.root.join('tmp').to_s}", "#{opac.to_s}.html")
    fd=File.open(fn,"w")
    fd.write(html)
    fd.close
  end
  def load_from_local_copy(opac)
    fn=File.join("#{Rails.root.join('tmp').to_s}", "#{opac.to_s}.html")
    Nokogiri::HTML(open(fn))
  end
  
end

