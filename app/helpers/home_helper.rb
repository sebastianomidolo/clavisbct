module HomeHelper

  def misc_periodici_musicale_in_ritardo
    sql=%Q{select op.excel_cell_id,ci.item_id,ci.title,
   ci.issue_status,lv.value_label as stato,
age(now()::date,ci.issue_arrival_date_expected) as ritardo,
ci.issue_arrival_date_expected as previsto
  from clavis.item ci
  join clavis.lookup_value lv on(ci.issue_status=lv.value_key)
  left join ordini_periodici_musicale op using(manifestation_id)
  where
   ci.owner_library_id=3
   and ci.issue_arrival_date_expected <= now()
   and value_language = 'it_IT' and value_class='ISSUESTATUS'
   and ci.issue_arrival_date_expected notnull
  and ci.issue_status in ('M','N','P')
--    and ci.issue_status in ('M')
--   order by age(now()::date,ci.issue_arrival_date_expected),ci.title,ci.issue_arrival_date_expected;
   order by ci.title,ci.issue_arrival_date_expected,age(now()::date,ci.issue_arrival_date_expected);}

    res=[]
    cnt=0
    ActiveRecord::Base.connection.execute(sql).each do |r|
      cnt+=1
      if r['excel_cell_id'].blank?
        lnk_excel= "#{cnt}."
        lnk_style=""
      else
        lnk_excel=link_to("#{cnt}.", excel_cell_path(r['excel_cell_id'].to_i))
        lnk_style={:class=>'success'}
      end
      res << content_tag(:tr,
                         content_tag(:td,lnk_excel,lnk_style) +
                         content_tag(:td, link_to(r['title'],
                                                  ClavisItem.clavis_url(r['item_id']))) +
                         content_tag(:td, r['previsto'].to_date) +
                         content_tag(:td, r['stato']) +
                         content_tag(:td, r['ritardo'], :class=>'danger'))
    end
    content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'),
                :class=>'table-responsive')
  end

  def misc_uni856(records)
    res=[]
    prec=''
    cnt=0
    res << content_tag(:tr, content_tag(:td, '') +
                            content_tag(:td, 'nota') +
                            content_tag(:td, 'creato da, modificato da') +
                            content_tag(:td, ''))
    
    records.each do |r|
      title=r['title'].blank? ? '[?]' : r['title']
      if r['nota']!=prec
        # cnt=0
        prec=r['nota']
      end
      cnt+=1
      res << content_tag(:tr, content_tag(:td, content_tag(:b, "#{cnt}.")) +
                              content_tag(:td, r['nota']) +
                              content_tag(:td, r['librarian_id']) +
                         content_tag(:td,
                                     link_to(title,
                                             ClavisManifestation.clavis_url(r['manifestation_id'],:edit)) +
                                     "<br/>#{r['url']}".html_safe))
    end
    content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'),
                :class=>'table-responsive')
  end

  def bidcr(records)
    res=[]
    cnt=0
    res << content_tag(:tr, content_tag(:td, content_tag(:b, "")) +
                         content_tag(:td, 'titolo') +
                         content_tag(:td, 'bid') +
                         content_tag(:td, 'bid_source') +
                         content_tag(:td, 'date_created') +
                         content_tag(:td, 'date_updated'))
    records.each do |r|
      cnt+=1
      res << content_tag(:tr, content_tag(:td, content_tag(:b, "#{cnt}")) +
                         content_tag(:td, r['title']) +
                         content_tag(:td, r['bid']) +
                         content_tag(:td, r['bid_source']) +
                         content_tag(:td, r['date_created']) +
                         content_tag(:td, r['date_updated']))
    end
    content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'),
                :class=>'table-responsive')
  end
  def bidcr_sommario(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Ora di creazione') +
                         content_tag(:td, 'Conteggio'))
    cnt=0
    tot=0
    records.each do |r|
      count=r['count'].to_i
      tot+=count
      cnt+=1
      res << content_tag(:tr, content_tag(:td, r['date_created']) +
                         content_tag(:td, count))
    end
    res << content_tag(:tr, content_tag(:td, content_tag(:b,'Totale record creati')) + content_tag(:td, tot), class:'danger')
    res << content_tag(:tr, content_tag(:td, content_tag(:b,'Media oraria')) + content_tag(:td, tot/cnt), class:'danger') if cnt>0
    content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'),
                :class=>'table-responsive')
  end

  def misc_esemplari_con_rfid(records)
    res=[]
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['biblioteca'],
                                                       esemplari_con_rfid_path(library_id:r['library_id'])),
                                          class:'col-md-4') +
                              content_tag(:td, r['count']))
    end
    content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'),
                :class=>'table-responsive')
  end

  def misc_dettaglio_esemplari_con_rfid(records, library_id, ancora_da_taggare)
    res=[]
    prec_cnt=0
    totale=0
    giorni=0
    res << content_tag(:tr, content_tag(:td, "Data taggatura", class:'col-md-2') +
                            content_tag(:td, "Tag inseriti", class:'col-md-1') +
                            content_tag(:td, "Totale progressivo", class:'col-md-2') +
                            content_tag(:td, "Giorni", class:'col-md-1') +
                            content_tag(:td, "Media giornaliera (arrotondata per eccesso)", class:'col-md-6'))
    records.each do |r|
      cnt=r['tagged_count'].to_i
      diff = prec_cnt==0 ? 0 : cnt-prec_cnt
      totale+=diff
      if diff!=0
        giorni+=1
        res << content_tag(:tr, content_tag(:td, r['snapshot_date'].to_date) +
                                content_tag(:td, diff) +
                                content_tag(:td, totale) +
                                content_tag(:td, giorni) +
                                content_tag(:td, "#{(totale/giorni.to_f).ceil}"))
      end
      prec_cnt=cnt
    end

    res << content_tag(:tr, content_tag(:td, "Ancora da taggare: #{ancora_da_taggare}"))
    if giorni>0
      res << content_tag(:tr, content_tag(:td, "Media su #{giorni} giorni: #{(totale/giorni.to_f).ceil}"))
      res << content_tag(:tr, content_tag(:td, "Giorni necessari: #{ancora_da_taggare/((totale/giorni.to_f).ceil)}"))
    end
    content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table'),
                :class=>'table-responsive')
  end

  def misc_dettaglio_esemplari_con_rfid_csv(records,library,header=true)
    res=[]
    res << "Library,Date,Count,Progr,Average" if header
    prec_cnt=0
    totale=0
    giorni=0
    records.each do |r|
      cnt=r['tagged_count'].to_i
      diff = prec_cnt==0 ? 0 : cnt-prec_cnt
      totale+=diff
      if diff!=0
        giorni+=1
        res << "#{library},#{r['snapshot_date'].to_date},#{diff},#{totale},#{totale/giorni.to_f}"
      end
      prec_cnt=cnt
    end
    res.join("\n")
  end

end
