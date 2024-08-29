module ClavisAuthoritiesHelper

  def clavis_authorities_list(records)
    res=[]
    records.each do |r|
      lnk=link_to(r.full_text, r.clavis_url(:show), :target=>'_blank')
      lnk2=link_to("[edit]", r.clavis_url(:edit), :target=>'_blank')
      sql_link = params[:authority_type] == 'A' ? link_to('sql', spacchetta_clavis_authority_path(r), class:'btn btn-warning') : ''
      res << content_tag(:tr, content_tag(:td, lnk2, class:'col-md-1') +
                              content_tag(:td, lnk, class:'col-md-3') +
                              content_tag(:td, sql_link, class:'col-md-1') +
                              content_tag(:td, r.bid_source, class:'col-md-2') +
                              content_tag(:td, r.bid, class:'col-md-2') + content_tag(:td, r.authority_type))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def clavis_authorities_dupl(records)
    res=[]
    records.each do |r|
      links=[]
      r.ids.gsub(/\{|\}/,'').split(',').each do |id|
        links << link_to(id, ClavisAuthority.clavis_url(id,:show), :target=>'_blank')
      end
      res << content_tag(:tr, content_tag(:td, r.count, class:'col-md-1') +
                              content_tag(:td, r.heading, class:'col-md-3') +
                              content_tag(:td, links.join("<br/>").html_safe, class:'col-md-9'))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def clavis_authority_show(record)
    res = []
    res << content_tag(:tr, content_tag(:td, "") + content_tag(:td, 'UP'))
    found = 0
    record.l_authorities('up').each do |r|
      res << content_tag(:tr, content_tag(:td, r.link_type) +
                              content_tag(:td, link_to(r.to_label, spacchetta_clavis_authority_path(r))))
    end
    res << content_tag(:tr, content_tag(:td, "") + content_tag(:td, 'DOWN'))
    record.l_authorities('down').each do |r|
      res << content_tag(:tr, content_tag(:td, r.link_type) +
                              content_tag(:td, link_to(r.to_label, spacchetta_clavis_authority_path(r))))
    end
    if found==0
      #record.dividi_soggetto.each do |r|
      #  res << content_tag(:tr, content_tag(:td, '') + content_tag(:td, r.inspect))
      #end
    end
    
    res=content_tag(:table, res.join.html_safe, {class: 'table table-condensed'})
  end

  def clavis_authority_manifestations(record)
    clavis_manifestations_shortlist(record.l_manifestations)
  end

  def clavis_authority_sql_for_spacchetta(record, au1=nil, au2=nil)
    res = []
    man_ids = record.l_manifestations.collect{|r| r.manifestation_id}
    res << "-- Codice aggiornato al 24 agosto 2023 - USARE CON CAUTELA\nBEGIN;"
    res << "UPDATE turbomarcauthority_cache SET dirty='1' WHERE authority_id=#{record.id};"
    res << "UPDATE turbomarc_cache SET dirty='1' WHERE manifestation_id in (#{man_ids.join(', ')});"

    cnt = 0
    record.l_authorities('up').each do |r|
      next if r.link_type.strip.to_i!=76

      res << "-- Legami tra authority #{r.id} e notizie #{man_ids.join(',')}"
      man_ids.each do |mid|
        cnt += 1
        res << "INSERT INTO l_authority_manifestation (authority_id,manifestation_id,link_type,relator_code) VALUES (#{r.id},#{mid},619,'');"
      end
    end
    if cnt == 0
      res << "-- inseriti #{cnt} legami con notizie"
      if au1.nil? or au2.nil?
        res << "-- Utilizzare la funzione dividi intestazione"
      else
        if au1>0 and au2>0
          a1 = ClavisAuthority.find(au1)
          a2 = ClavisAuthority.find(au2)
          res << "-- Risultato della divisione: 1. elemento: #{a1.to_label}"
          res << "-- Risultato della divisione: 2. elemento: #{a2.to_label}"
          man_ids.each do |mid|
            res << "INSERT INTO l_authority_manifestation (authority_id,manifestation_id,link_type,relator_code) VALUES (#{a1.id},#{mid},619,'');"
            res << "INSERT INTO l_authority_manifestation (authority_id,manifestation_id,link_type,relator_code) VALUES (#{a2.id},#{mid},619,'');"
          end
        end
      end
    end

    res << "-- Ora dovrei eliminare il legame tra authority #{record.id} le seguenti manifestation: #{man_ids.sort.uniq}"
    res << "DELETE FROM l_authority_manifestation WHERE authority_id=#{record.id} and manifestation_id IN (#{man_ids.join(', ')});"
    res << "COMMIT;"
    
    content_tag(:pre, res.join("\n"))
  end
end
