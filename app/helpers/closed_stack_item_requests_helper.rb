module ClosedStackItemRequestsHelper

  def closed_stack_item_requests_list(dng_session,target_div)
    res = []
    heading = content_tag(:tr, content_tag(:th, '', class:'col-md-1') +
                               content_tag(:th, "<b>Collocazione</b>".html_safe, class:'col-md-1') +
                               content_tag(:th, 'Titolo', class:'col-md-4') +
                               content_tag(:th, 'Richiesto alle') +
                               content_tag(:th, 'Confermato alle') +
                               content_tag(:th, 'Stampato alle'))

    return '' if dng_session.nil?

    patron=ClavisPatron.find(dng_session.patron_id)
    # patron=ClavisPatron.find(77244)
    patron.closed_stack_item_requests.each do |ir|
      item=ClavisItem.find(ir.item_id)
      title=link_to(item.title[0..50], ClavisManifestation.clavis_url(item.manifestation_id, :opac))

      url="https://#{request.host_with_port}#{item_delete_closed_stack_item_request_path(ir,dng_user:patron.opac_username,target_div:target_div,format:'js')}"
      canc_lnk=link_to('cancella',url,remote:true,title:'Elimina questa richiesta', method: :get, data: {confirm: 'Vuoi eliminare la richiesta?'}) if ir.confirm_time.nil?
      # canc_lnk=link_to('cancella',url,remote:true,title:'Elimina questa richiesta', method: :get) if ir.confirm_time.nil?

      res << content_tag(:tr, content_tag(:td, canc_lnk) +
                              content_tag(:td, item.la_collocazione) +
                              content_tag(:td, title) +
                              content_tag(:td, closed_stack_item_requests_ora(ir.request_time)) +
                              content_tag(:td, closed_stack_item_requests_ora(ir.confirm_time)) +
                              content_tag(:td, closed_stack_item_requests_ora(ir.print_time)))
    end
    return 'Non ci sono richieste a magazzino' if res == []
    res.unshift(heading)

    ticket=patron.csir_tickets.join(', ')
    ticket = " - Numero di chiamata: #{content_tag(:b, ticket)}" if !ticket.blank?

    content_tag(:h3, %Q{Richieste a magazzino#{ticket}}.html_safe) +
      content_tag(:table, res.join.html_safe, class:'table text-success')
  end

  def closed_stack_item_requests_ora(time)
    if time.class==String
      time = time.to_time
    end
    # time.blank? ? '' : time.in_time_zone('Europe/Rome').strftime('%H:%M')
    time.blank? ? '' : time.in_time_zone('Europe/Rome').strftime('%H:%M')
  end

  def closed_stack_item_requests_index(records, patron, da_clavis=false)
    return if records.size==0
    heading = content_tag(:tr, content_tag(:th, '', class:'col-md-1') +
                               content_tag(:th, "Piano", class:'col-md-1') +
                               content_tag(:th, "<b>Collocazione</b>".html_safe) +
                               content_tag(:th, 'Titolo', class:'col-md-2') +
                               content_tag(:th, 'Inventario') +
                               content_tag(:th, 'Richiesta') +
                               content_tag(:th, 'Conferma') +
                               content_tag(:th, 'Stampa') +
                               content_tag(:th, 'Numero per il ritiro'))
    res=[]
    confirm_request=false
    print_request=false
    archived_request=false
    records.each do |r|
      confirm_request = true if r.daily_counter.nil?
      archived_request = true if r.archived==true
      # confirm_time = r.confirm_time.nil? ? '' : r.confirm_time.in_time_zone('Europe/Rome').strftime('%d-%m-%Y %H:%M')
      confirm_time = r.confirm_time.nil? ? '' : r.confirm_time.in_time_zone('Europe/Rome').strftime('%H:%M')
      if r.print_time.nil?
        print_time = ''
        lnk = link_to('[elimina]', "https://#{request.host_with_port}#{csir_delete_closed_stack_item_request_path(r.id, format:'js')}", remote:true, method: :get)
      else
        print_time = r.print_time.in_time_zone('Europe/Rome').strftime('%H:%M')
        txt = r.archived? ? 'dearchivia' : 'archivia'
        lnk = link_to("[#{txt}]", "https://#{request.host_with_port}#{csir_archive_closed_stack_item_request_path(r.id, format:'js')}", remote:true, method: :get)
      end
      lnk = '' if da_clavis
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.piano) +
                              content_tag(:td, "<b>#{r.collocazione}</b>".html_safe) +
                              content_tag(:td, r['title'][0..20]) +
                              content_tag(:td, r.serieinv) +
                              content_tag(:td, r.request_time.in_time_zone('Europe/Rome').strftime('%H:%M')) +
                              content_tag(:td, confirm_time) +
                              content_tag(:td, print_time) +
                              content_tag(:td, r.daily_counter),
                         id:"csir_#{r.id}")
      print_request = true if !print_time.blank?
    end
    if !archived_request
      if confirm_request
        lnk = "https://#{request.host_with_port}#{confirm_request_closed_stack_item_requests_path(patron_id:patron.id, format:'js')}"
        cmd = %Q{<span id="conferma_richieste">#{link_to('<b>[Conferma le richieste (solo in presenza dell\'utente che le ha inserite)]</b>'.html_safe, lnk,remote:true,title:'Conferma le richieste', method: :get)}</span>}.html_safe
      else
        if print_request.blank?
          cmd = link_to("<b>[Stampa richieste a magazzino]</b>".html_safe, print_closed_stack_item_requests_path(patron_id:patron), title:"Stampa richieste per singolo utente")
        else
          cmd = link_to("<b>[Ristampa richieste a magazzino]</b>".html_safe, print_closed_stack_item_requests_path(patron_id:patron,reprint:true), title:"Ristampa richieste per singolo utente")
        end
      end
    end
    ids = records.collect{|x| x.item_id}
    link = link_to('In Clavis', ClavisItem.clavis_url(ids))
    res.unshift(heading)
    cmd = '' if da_clavis
    content_tag(:h2, "#{cmd}".html_safe) +
      content_tag(:table, res.join("\n\n").html_safe, class:'table text-success') +
      content_tag(:p, link)
  end

  def closed_stack_item_requests_stats(params)
    cond = ''
    days = params[:days].to_i
    if params[:confirmed].blank? or params[:confirmed]=='true'
      confirm_condition = 'notnull'
      heading = "confermate"
      ttime = 'confirm_time'
    else
      confirm_condition = 'is null'
      heading = "non confermate"
      ttime = 'request_time'
    end
    if days > 0
      cond = "and #{ttime} between now() - interval '#{days} days' and now()"
      quando = (days==1 ? " (oggi)" : " (ultimi #{days} giorni)")
      heading << quando
    end

    sql=%Q{select piano,count(*) from closed_stack_item_requests ir join clavis.centrale_locations cl using(item_id)
         where confirm_time #{confirm_condition} #{cond} group by piano order by count(*) desc}
    q=ActiveRecord::Base.connection.execute(sql).to_a
    res=[]

    res << content_tag(:tr, content_tag(:th, 'Piano', class:'col-md-3') +
                            content_tag(:th, "Numero richieste #{heading}"))
    totale=0
    q.each do |r|
      totale = totale + r['count'].to_i
      res << content_tag(:tr, content_tag(:td, r['piano']) +
                              content_tag(:td, r['count']))
    end
    res << content_tag(:tr, content_tag(:th, 'Totale') +
                            content_tag(:th, totale))
    links = []
    links << link_to('Oggi', stats_closed_stack_item_requests_path(days:1))
    links << link_to('Ultimi 30 giorni', stats_closed_stack_item_requests_path(days:30))
    links << link_to('Tutte', stats_closed_stack_item_requests_path)
    links << link_to("Non confemate#{quando}", stats_closed_stack_item_requests_path(confirmed:false,days:params[:days]))

    content_tag(:div, "Richieste a magazzino Civica Centrale: #{links.join(' | ')}".html_safe) +
      content_tag(:table, res.join("\n\n").html_safe, class:'table text-success') +
      content_tag(:pre, sql)
  end

  def closed_stack_item_requests_autoprint_requests(all=nil)
    fname='/home/seb/autoprintweb.log'
    if all.nil?
      require 'open3'
      cmd = "/usr/bin/tail -60  #{fname} | /usr/bin/tac"
      a,b,c,d=Open3.popen3(cmd)
      b.read
    else
      File.read(fname)
    end
  end

  def closed_stack_item_requests_patrons_index
    res = []
    res << content_tag(:h3, "Richieste di oggi (prossimo numero di ticket: <b>#{DailyCounter.last.id}</b>)".html_safe)

    t = closed_stack_item_requests_patrons(ClosedStackItemRequest.patrons(true,false))
    (res << content_tag(:h3, "Da Confermare [solo in presenza di chi ha fatto le richieste]"); res << t) if !t.blank?

    t = closed_stack_item_requests_patrons(ClosedStackItemRequest.patrons(false,false))
    (res << content_tag(:h3, "Confermate, da stampare"); res << t;  res << content_tag(:h3, link_to('Stampa elenco per magazzino', print_closed_stack_item_requests_path(format:'html')))) if !t.blank?

    t = closed_stack_item_requests_patrons(ClosedStackItemRequest.patrons(false,true))
    (res << content_tag(:h3, "Richieste stampate"); res << t) if !t.blank?
    res.join.html_safe
  end

  def closed_stack_item_requests_da_stampare
    res = []

    ClosedStackItemRequest.patrons(false,false).each do |r|
      lnk = link_to("<b>#{r['barcode']}</b>".html_safe, ClavisPatron.clavis_url(r['patron_id'],:newloan), target:'_blank')
      txt = "<b>[Stampa #{r['count']} richieste a magazzino]</b>"
      prt = link_to(txt.html_safe, print_closed_stack_item_requests_path(patron_id:r['patron_id']), title:"Stampa richieste per singolo utente")
      res << content_tag(:tr, content_tag(:td, "#{r['name']} #{r['lastname']}", class:'col-md-2') +
                              content_tag(:td, lnk, class:'col-md-1') +
                              content_tag(:td, prt))
    end
    ClosedStackItemRequest.patrons(false,true).each do |r|
      lnk = link_to("<b>#{r['barcode']}</b>".html_safe, ClavisPatron.clavis_url(r['patron_id'],:newloan), target:'_blank')
      txt = "<b>[Ristampa #{r['count']} richieste a magazzino]</b>"
      prt = link_to(txt.html_safe, print_closed_stack_item_requests_path(patron_id:r['patron_id'],reprint:true), title:"Ristampa richieste per singolo utente")
      res << content_tag(:tr, content_tag(:td, "#{r['name']} #{r['lastname']}", class:'col-md-2') +
                              content_tag(:td, lnk, class:'col-md-1') +
                              content_tag(:td, prt))
    end

    content_tag(:table, res.join.html_safe, class:'table')
  end

  def closed_stack_item_requests_patrons(records)
    return '' if records.size==0
    res=[]
    records.each do |r|
      lnk1 = link_to("<b>#{r['barcode']}</b>".html_safe, ClavisPatron.clavis_url(r['patron_id'],:newloan), target:'_blank')
      # lnk2 = link_to("<b>#{r['lastname']}</b>".html_safe, closed_stack_item_requests_path(patron_id:r['patron_id']))
      lnk2 = link_to("#{r['name']} <b>#{r['lastname']}</b>".html_safe, clavis_patron_path(r['patron_id']))
      res << content_tag(:tr, content_tag(:td, lnk1, class:'col-md-2') +
                              content_tag(:td, lnk2, class:'col-md-3') +
                              content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe, class:'table text-success')
  end

  def closed_stack_item_requests_oggi
    res=[]
    cnt=0
    ClosedStackItemRequest.oggi.each do |r|
      cnt+=1
      lnk1 = link_to("#{r.name} <b>#{r.lastname}</b>".html_safe, clavis_patron_path(r.patron_id), target:'_blank')
      itemlnk = link_to(r.title, ClavisItem.clavis_url(r.item_id))
      res << content_tag(:tr, content_tag(:td, cnt, class:'col-md-1') +
                              content_tag(:td, r.request_time.in_time_zone('Europe/Rome').strftime('%H:%M'), class:'col-md-1') +
                              content_tag(:td, r.collocazione, class:'col-md-2') +
                              content_tag(:td, lnk1, class:'col-md-2') +
                              content_tag(:td, itemlnk, class:'col-md-6'))
    end
    content_tag(:table, res.join.html_safe, class:'table text-success')
  end

  def closed_stack_item_requests_logfile(requests)
    res=[]
    res << content_tag(:tr, content_tag(:td, "titolo")+
                            content_tag(:td, "richiesto da") +
                            content_tag(:td, "ora richiesta") +
                            content_tag(:td, "ora conferma") +
                            content_tag(:td, "confermato da") +
                            content_tag(:td, "ora stampa") +
                            content_tag(:td, "IP o Inserito da"))

    requests.each do |r|
      lnk_tit = 1;
      itemlnk = link_to(r.title, ClavisItem.clavis_url(r.item_id))
      patronlnk = link_to(r.patron_barcode, ClavisPatron.clavis_url(r.patron_id))
      if r.client_ip.nil?
        ip_or_created_by = r.u_created_by
        ip_or_created_by_title = "inserito da #{r.u_created_by}"
      else
        ip_or_created_by = r.client_ip
        ip_or_created_by_title = "inserito da Opac"
      end
      confirm_time = r.confirm_time.nil? ? 'non confermato' : r.confirm_time.in_time_zone('Europe/Rome').strftime('%H:%M')
      print_time = r.print_time.nil? ? 'non stampato' : r.print_time.in_time_zone('Europe/Rome').strftime('%H:%M')
      res << content_tag(:tr, content_tag(:td, itemlnk)+
                              content_tag(:td, patronlnk, {title:"#{r.patron_name} #{r.patron_lastname}"}) +
                              content_tag(:td, r.request_time.in_time_zone('Europe/Rome').strftime('%d/%m/%Y %H:%M'), class:'col-md-1') +
                              content_tag(:td, confirm_time, class:'col-md-1') +
                              content_tag(:td, r.u_confirmed_by, {title:"confermato da #{r.l_confirmed_by}"}) +
                              content_tag(:td, print_time, class:'col-md-1') +
                              content_tag(:td, ip_or_created_by, {title:ip_or_created_by_title}))
    end
    content_tag(:table, res.join.html_safe, class:'table text-success')
  end
end
