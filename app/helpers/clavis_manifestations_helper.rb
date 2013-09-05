# -*- coding: utf-8 -*-
# lastmod 20 febbraio 2013

module ClavisManifestationsHelper
  def clavis_manifestation_view(record)
    config = Rails.configuration.database_configuration
    r=[]
    # lnk=content_tag(link_to(record.title, record.clavis_url))
    lnk=link_to(record.title, record.clavis_url(:opac))
    r << content_tag(:div, content_tag(:b, lnk))
    r << content_tag(:div, clavis_issue_list(record))
    r.join.html_safe
  end

  def clavis_manifestation_opac_preview(record)
    %Q{<iframe src="http://bct.comperio.it/opac/detail/badge/sbct:catalog:#{record.id}?height=300&showabstract=1&coversize=normal" frameborder="0" width="600" height="300"></iframe>}.html_safe
  end

  def clavis_manifestations_shortlist(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'BID') +
                       content_tag(:td, 'level') +
                       content_tag(:td, 'type') +
                       content_tag(:td, 'created') +
                       content_tag(:td, 'modif') +
                       content_tag(:td, '') +
                       content_tag(:td, '') +
                       content_tag(:td, ''))

    records.each do |r|
      tit=r.title.blank? ? '[vedi titolo]' : r.title[0..80]
      res << content_tag(:tr, content_tag(:td, r.thebid) +
                         content_tag(:td, r.bib_level) +
                         content_tag(:td, r.bib_type) +
                         content_tag(:td, r.created_by) +
                         content_tag(:td, r.modified_by) +
                         content_tag(:td, link_to('[opac]', r.clavis_url(:opac), :target=>'_blank')) +
                         content_tag(:td, link_to('[edit]', r.clavis_url(:edit), :target=>'_blank')) +
                         content_tag(:td, link_to(tit, r.clavis_url, :target=>'_blank')))
    end
    content_tag(:table, res.join.html_safe)
  end


  def clavis_manifestations_perbid
    sql="select bid_source,count(*) from clavis.manifestation where bib_level in('m','c','s') group by bid_source order by bid_source;"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      if r['bid_source'].blank?
        r['bid_source']='null'
        txt='[missing]'
      else
        txt=r['bid_source']
      end
      res << content_tag(:tr, content_tag(:td, r['count']) +
                         content_tag(:td, txt) +
                         content_tag(:td, link_to('collane', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'c'))) +
                         content_tag(:td, link_to('monografie', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'m'))) +
                         content_tag(:td, link_to('seriali', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source'], :bib_level=>'s'))) +
                         content_tag(:td, link_to('tutto', shortlist_clavis_manifestations_url(:bid_source=>r['bid_source']))))
    end
    res << content_tag(:td, link_to('polo bct', shortlist_clavis_manifestations_url(:bid_source=>'SBN', :polo=>'BCT')))
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestations_oggbibl
    sql="select value_key,value_label,value_class from clavis.lookup_value where value_language='it_IT' AND value_class ~* '^OGGBIBL_' order by value_key"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      # http://clavisbct.selfip.net/clavis_manifestations/shortlist?bib_type=a02
      res << content_tag(:tr, content_tag(:td, r['value_key']) +
                         content_tag(:td, link_to(r['value_label'], shortlist_clavis_manifestations_url(:bib_type=>r['value_key']))) +
                         content_tag(:td, link_to("#{r['value_key']} (senza bid)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'null'))) +
                         content_tag(:td, link_to("#{r['value_key']} (LOC)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'LOC'))) +
                         content_tag(:td, link_to("#{r['value_key']} (UKLIB)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'UKLIB'))) +
                         content_tag(:td, link_to("#{r['value_key']} (FRLIB)", shortlist_clavis_manifestations_url(:bib_type=>r['value_key'], :bid_source=>'FRLIB'))))
    end
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestations_attachments_summary
    sql=%Q{select trim(cm.title) as title,cm.manifestation_id,ac.label,count(*) from attachments a join attachment_categories ac on(a.attachment_category_id=ac.code) join clavis.manifestation as cm on(a.attachable_id=cm.manifestation_id) group by cm.title,cm.sort_text,cm.manifestation_id,ac.label order by ac.label desc,lower(trim(cm.sort_text));}
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    cnt=0
    pg.each do |r|
      cnt+=1
      lnk="http://bct.comperio.it/opac/detail/view/sbct:catalog:#{r['manifestation_id']}"
      res << content_tag(:tr, content_tag(:td, cnt) +
                         content_tag(:td, link_to(r['title'], lnk)) +
                         content_tag(:td, r['label']) +
                         content_tag(:td, link_to('vedi',
                  clavis_manifestation_path(r['manifestation_id'], :dng_user=>params[:dng_user]))) +
                         content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestation_pdf_links(record)
    res=[]
    n=0
    record.attachments_generate_pdf(false).each do |fname|
      ac=access_control_key
      # res << content_tag(:tr, content_tag(:td, ac))
      next if ac.nil? or ac!=params[:ac]
      dng_session = DngSession.find_by_params_and_request(params,request)
      if !dng_session.check_service('download_pdf',params,request,record)
        return false
      end
      text=n
      dg=Digest::MD5.hexdigest(fname)
      lnk=link_to("Scarica file in formato PDF: pdf_file_#{n+1}",attachments_clavis_manifestation_path(record, :format=>'pdf', :fkey=>dg,:filenum=>n, :ac=>ac, :dng_user=>params[:dng_user]))
      res << content_tag(:tr, content_tag(:td, lnk) +
                         content_tag(:td, number_to_human_size(File.size(fname))))
      n+=1
    end
    content_tag(:table, res.join.html_safe)
  end

  def clavis_manifestation_show_attachments(record,params,request,dng_session)
    return [nil,nil] if record.attachments.size==0
    content=tabtitle=testo_avviso=nil
    if record.bib_type=='i05'
      # Libro parlato
      tabtitle="Audio libro parlato"
      if dng_session.nil?
        content="La sessione di lavoro risulta scaduta - è necessario effettuare nuovamente l'accesso"
      else
        if dng_session.check_service('talking_book',params,request)
          content=content_tag(:div, attachments_render(record.attachments))
        else
          content="#{dng_session.patron.appellativo}, Lei non risulta iscritto al Servizio Libro parlato"
        end
      end
    else
      x=record.attachments.first.attachment_category
      x = x.nil? ? 'Allegati' : x.label
      tabtitle="#{x}"
      testo_avviso="Informazione: il contenuto di questa pagina, inserito a titolo sperimentale, potrebbe contenere errori e cambiare senza preavviso"
      content=content_tag(:div, attachments_render(record.attachments))
    end
    return [nil,nil] if content.blank?
    [tabtitle,content_tag(:span, testo_avviso) + content_tag(:div, content)]
  end

end
