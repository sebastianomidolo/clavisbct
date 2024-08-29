# coding: utf-8
module LocationsHelper
  def locations_list(records, order='')
    res = []
    if order=='p'
      col2='Ubicazione'
      col3='Collocazione'
    else
      col2='Collocazione'
      col3='Ubicazione'
    end
    
    res << content_tag(:tr, content_tag(:td, col2, class:'col-md-3') +
                            content_tag(:td, col3, class:'col-md-3') +
                            content_tag(:td, 'Filtro su collocazione', class:'col-md-2') +
                            content_tag(:td, 'Annotazioni'))
    records.each do |r|
      lnkcolloc=link_to(r.collocazione_intera.html_safe, location_path(r), class:'btn btn-info', title:'Vedi esemplari', target:'_new')
      if order=='p'
        col2=link_to(r.loc_name, bib_section_path(r.bib_section_id))
        col3=lnkcolloc
      else
        col2=lnkcolloc
        # col3=r.loc_name
        col3=link_to(r.loc_name, bib_section_path(r.bib_section_id))
      end
      col2 = content_tag(:b, col2) if !col2.nil? and r.locked
      res << content_tag(:tr, content_tag(:td, col2) +
                              content_tag(:td, col3) +
                              content_tag(:td, r.sql_filter) +
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

  def schema_collocazioni_centrale_items_series(record,verbose=true)
    verbose = false ; # comunque "false" per evitare che serie inventariali non legate alla biblioteca non appaiono (vedi fondo CLA)
    res = []
    res << content_tag(:tr, content_tag(:td, 'SerieId', class:'col-md-2') +
                            content_tag(:td, 'Descrizione', class:'col-md-2') +
                            content_tag(:td, 'Numero volumi', class:'col-md-8'))
    piano = record.bib_section.name
    record.items_series(verbose=verbose,exec=true).each do |r|
      lnk = clavis_items_path(piano:piano,"clavis_item[home_library_id]":record.library_id,schema_collocazione_centrale:record.id,"clavis_item[inventory_serie_id]":r['serie'],with_manifestations:'')
      res << content_tag(:tr, content_tag(:td, r['serie']) +
                              content_tag(:td, r['description']) +
                              content_tag(:td, link_to(r['volumi'],lnk,class:'btn btn-info')))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end
  def schema_collocazioni_centrale_items_edition_dates(record,verbose=true)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Anno di pubblicazione', class:'col-md-2') +
                            content_tag(:td, 'Numero volumi', class:'col-md-8'))
    piano = record.bib_section.name
    record.items_edition_dates(verbose=verbose,exec=true).each do |r|
      lnk = clavis_items_path(piano:piano,"clavis_item[home_library_id]":record.library_id,schema_collocazione_centrale:record.id,edition_date:r['edition_date'],with_manifestations:'S')
      res << content_tag(:tr, content_tag(:td, r['edition_date']) +
                              content_tag(:td, link_to(r['volumi'],lnk,class:'btn btn-info')))
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def locations_libraries
    res = []
    ActiveRecord::Base.connection.execute("select cl.library_id,cl.label,count(*) from view_locations sc join clavis.library cl using(library_id) group by cl.library_id order by cl.label").each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['label'],locations_path(library_id:r['library_id']))) +
                              content_tag(:td, link_to("ubicazioni per #{r['label']}", bib_sections_path(library_id:r['library_id']))))
    end
    content_tag(:table, res.join.html_safe, class:'table')    
  end

  def locations_breadcrumbs
    # return params.inspect
    links=[]
    links << link_to('Tabelle di Collocazione BCT', locations_path, {title:'Home page schema collocazioni'})
    links << link_to(@clavis_library.label, locations_path(library_id:@clavis_library)) if !@clavis_library.nil?
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
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
