module SchemaCollocazioniCentraleHelper
  def schema_collocazioni_centrale_list(records, order)
    res = []
    if order=='p'
      col2='Piano'
      col3='Scaffale'
    else
      col2='Scaffale'
      col3='Piano'
    end
    
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, col2, class:'col-md-2') +
                            content_tag(:td, col3, class:'col-md-2') +
                            content_tag(:td, 'Palchetto', class:'col-md-1') +
                            content_tag(:td, 'Filtro collocazione', class:'col-md-2') +
                            content_tag(:td, 'Annotazioni'))
    records.each do |r|
      if order=='p'
        col2=r.piano
        col3=r.scaffale
      else
        col2=r.scaffale
        col3=r.piano
      end
      col2 = content_tag(:b, col2) if !col2.nil? and r.locked
      lnk = user_signed_in? ? link_to('[vedi]', schema_collocazioni_centrale_path(r)) : ''
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, col2) +
                              content_tag(:td, col3) +
                              content_tag(:td, r.palchetto) +
                              content_tag(:td, r.filtro_colloc) +
                              content_tag(:td, r.notes))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def schema_collocazioni_centrale_vedi_esempi(record)
    sql=record.sql_for_select_from_centrale_locations
    return if sql.nil?
    q=ActiveRecord::Base.connection.execute(sql)
    res = []
    res << content_tag(:tr, content_tag(:td, 'collocazione', class:'col-md-2') +
                            content_tag(:td, 'piano', class:'col-md-2') +
                            content_tag(:td, 'scaffale', class:'col-md-1') +
                            content_tag(:td, 'primo', class:'col-md-1') +
                            content_tag(:td, 'secondo', class:'col-md-2') +
                            content_tag(:td, 'terzo', class:'col-md-2') +
                            content_tag(:td, 'catena', class:'col-md-1') +
                            content_tag(:td, 'item'))
    q.to_a.each do |r|
      lnk=link_to(r['item_id'], ClavisItem.clavis_url(r['item_id'],:show), :target=>'_blank')
      lnk=link_to(r['item_id'], clavis_item_path(r['item_id']), :target=>'_blank')
      res << content_tag(:tr, content_tag(:td, r['collocazione']) +
                              content_tag(:td, r['piano']) +
                              content_tag(:td, r['scaffale']) +
                              content_tag(:td, r['primo_elemento']) +
                              content_tag(:td, r['secondo_elemento']) +
                              content_tag(:td, r['terzo_elemento']) +
                              content_tag(:td, r['catena']) +
                              content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def schema_collocazioni_centrale_riepilogo
    res=[]
    pg=ActiveRecord::Base::connection.execute %Q{select piano,count(*) from clavis.centrale_locations group by piano order by piano}
    pg.to_a.each do |r|
      res << content_tag(:tr, content_tag(:td, r['piano'], class:'col-md-2') +
                              content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

    def schema_collocazioni_centrale_non_assegnati
    res=[]
    pg=ActiveRecord::Base::connection.execute %Q{select primo_elemento,count(*) from clavis.centrale_locations where piano is null group by primo_elemento order by count(*) desc}
    pg.to_a.each do |r|
      lnk=link_to(r['primo_elemento'], see_schema_collocazioni_centrales_path(r))
      res << content_tag(:tr, content_tag(:td, lnk, class:'col-md-2') +
                              content_tag(:td, r['count']))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

end
