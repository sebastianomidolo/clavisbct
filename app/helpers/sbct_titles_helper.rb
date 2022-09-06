# coding: utf-8
module SbctTitlesHelper

  def sbct_titles_con_prenotazioni(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Titolo', class:'col-md-4') +
                            content_tag(:td, 'EAN', class:'col-md-1') +
                            content_tag(:td, 'ISBN', class:'col-md-1') +
                            content_tag(:td, 'Prenotazioni pendenti', class:'col-md-1') +
                            content_tag(:td, 'Esemplari disponibili', class:'col-md-1') +
                            content_tag(:td, 'Percentuale di prenotazioni che possono essere soddisfatte', class:'col-md-4'), class:'success')
    records.each do |r|
      lnk = r.acquisti_id_titolo.nil? ? "#{r.ISBNISSN}<br/>(non individuato sul db acquisti)".html_safe : link_to(r.ISBNISSN, sbct_title_path(r.acquisti_id_titolo), target:'_blank')
      res << content_tag(:tr, content_tag(:td, link_to(r.title, r.clavis_url, target:'_blank')) +
                              content_tag(:td, r.EAN) +
                              content_tag(:td, lnk) +
                              content_tag(:td, r.reqnum) +
                              content_tag(:td, r.available_items) +
                              content_tag(:td, r.percentuale_di_soddisfazione + '%'))
    end

    return '' if res.size==0
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def sbct_short_titles_list(records, table_title='')
    return '' if records.size==0
    res = []
    res << content_tag(:tr, content_tag(:td, "EAN") +
                            content_tag(:td, "Autore") +
                            content_tag(:td, "Titolo"), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, r.ean) +
                              content_tag(:td, r.autore) +
                              content_tag(:td, r.titolo))
    end
    table_title + content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  
  def sbct_titles_list(records, managed_libraries)
    res=[]
    covers = params[:nocovers].blank? ? content_tag(:td, 'copertina', class:'col-md-1') : ''

    res << content_tag(:tr, covers.html_safe +
                            content_tag(:td, 'autore', class:'col-md-2') +
                            content_tag(:td, 'titolo/collana', class:'col-md-4') +
                            content_tag(:td, 'editore', class:'col-md-2') +
                            content_tag(:td, 'prezzo', class:'col-md-1') +
                            content_tag(:td, 'siglebib', class:'col-md-2') +
                            content_tag(:td, 'isbn', class:'col-md-2') +
                            content_tag(:td, '') +
                            content_tag(:td, ''), class:'success')

    if managed_libraries.size > 6
      sel_span_1 = 1
      sel_span_2 = 7
    else
      sel_span_1 = covers.blank? ? 4 : 5
      sel_span_2 = covers.blank? ? 3 : 4
    end

    libraries_with_code={}
    ClavisLibrary.con_siglabct.collect {|r| libraries_with_code[r.siglabct]=r}
    
    id_lista = params[:id_lista]
    records.each do |r|
      clavis_link = r.manifestation_id.nil? ? '' : link_to('Clavis', ClavisManifestation.clavis_url(r.manifestation_id), target:'_new')
      pproposal_link = r.respond_to?('proposal_id') ? link_to('proposta',clavis_purchase_proposal_path(r.proposal_id)) : ''
      glink = r.isbn.blank? ? 'manca isbn' : link_to(r.isbn, "https://www.google.com/search?q=#{r.isbn}", target:'_blank', title:'Cerca su Google')
      extlnk = []
      if !r.isbn.blank?
        extlnk << r.isbn
        extlnk << link_to('Leggere', "http://h3ol.leggere.it/?q=#{r.isbn}&p=ricercalibera".html_safe, target:'_blank', title:'Vedi su Leggere')
        extlnk << link_to('IBS', "https://www.ibs.it/bct/e/#{r.isbn}".html_safe, target:'_blank', title:'Vedi su IBS')
        extlnk << link_to('Google', "https://www.google.com/search?q=#{r.isbn}".html_safe, target:'_blank', title:'Vedi su Google')
        img_link = image_tag("https://covers.comperio.it/calderone/viewmongofile.php?ean=#{r.isbn}")
      else
        img_link = ''
      end
      lacollana = r.collana.blank? ? '' : "<br/><em>Collana: #{link_to(r.collana, sbct_titles_path("sbct_title[collana]":r.collana,id_lista:id_lista))}</em>".html_safe
      datapubbl = r.datapubblicazione.blank? ? '' : "<br/><b>Data di pubblicazione: #{r.datapubblicazione}</em>".html_safe
      anno = r.anno.blank? ? '' : "<br/><b>Anno: #{r.anno}</em>".html_safe
      cover_image = params[:nocovers].blank? ? content_tag(:td, img_link) : ''

      res << content_tag(:tr, content_tag(:td, '', colspan:sel_span_1) +
                              content_tag(:td, sbct_titles_user_checkbox(managed_libraries,@sbct_list,r.id,r.library_codes,libraries_with_code), colspan:sel_span_2),class:'active') if params[:selection_mode]=='S'
      res << content_tag(:tr, cover_image.html_safe +
                              content_tag(:td, (r.autore.blank? ? '' : link_to(r.autore, sbct_titles_path("sbct_title[autore]":r.autore,id_lista:id_lista)))) +
                              content_tag(:td, link_to(r.titolo,sbct_title_path(r.id_titolo, :page=>params[:page], budget_id:params[:budget_id], id_lista:id_lista, selection_mode:params[:selection_mode]), target:'_blank') + lacollana + datapubbl + anno) +
                              content_tag(:td, link_to(r.editore, sbct_titles_path("sbct_title[editore]":r.editore,id_lista:id_lista))) +
                              content_tag(:td, number_to_currency(r.prezzo)) +
                              content_tag(:td, content_tag(:b, ClavisLibrary.library_ids_to_siglebct(r.library_ids).sort.join(', '), id:"toc_#{r.id_titolo}")) +
                              content_tag(:td, extlnk.join(', ').html_safe) +
                              content_tag(:td, pproposal_link) +
                              content_tag(:td, clavis_link), id:"title_#{r.id}")
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
    # content_tag(:table, res.join("\n").html_safe, class:'table table-striped')
  end

  def sbct_titles_user_checkbox(managed_libraries,sbct_list,id_titolo,library_codes,libraries_with_code)
    library_codes=library_codes.split(',')
    res = []
    managed_libraries.each do |e|
      res << %Q{#{e}#{check_box_tag :choose, true, library_codes.include?(e), onclick:"toggle_library_selection(this,'#{libraries_with_code[e].library_id}',#{id_titolo},#{sbct_list.id})"}}
    end
    res.join("\n").html_safe
  end

  
  def sbct_titles_show_title(record)
    res=[]
    # res << content_tag(:tr, content_tag(:td, 'Campo') + content_tag(:td, 'Valore'), class:'active')
    record.attributes.keys.each do |k|
      next if record[k].blank?
      txt = record[k]
      if k == 'prezzo'
        res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, number_to_currency(txt)))
      else
        if k=='id_titolo'
          if can? :manage, SbctTitle
            lnk1 = lnk2 = ''
            if record.date_created.nil?
              lnk = link_to("<b>Modifica scheda #{record.id} su sistema CR originale</b>".html_safe, record.sistema_centrorete_url, target:'_blank')
            else
              lnk = link_to("<b>Modifica scheda #{record.id}</b>".html_safe, edit_sbct_title_path(record.id), class:'btn btn-warning', target:'_blank')
            end
          end
          res << content_tag(:tr, content_tag(:td, k) + content_tag(:td, lnk))
        else
          res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, txt))
        end
      end
    end
    res << content_tag(:tr, content_tag(:td, link_to('Copie', sbct_items_path("sbct_item[id_titolo]":record.id_titolo))) + content_tag(:td, sbct_libraries(record)))
    # res << content_tag(:tr, content_tag(:td, 'Copie') + content_tag(:td, sbct_libraries(record)))
    res << content_tag(:tr, content_tag(:td, 'già in Clavis') + content_tag(:td, sbct_presenti_in_clavis(@esemplari_presenti_in_clavis))) if @esemplari_presenti_in_clavis.size > 0
    res=content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

  def sbct_titles_db_originale(record)
    return nil if record.nil?
    res=[]
    # res << content_tag(:tr, content_tag(:td, 'Campo') + content_tag(:td, 'Valore'), class:'active')
    record.attributes.keys.each do |k|
      next if record[k].blank?
      txt = record[k]
      res << content_tag(:tr, content_tag(:td, k.capitalize) + content_tag(:td, txt))
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end


  def sbct_libraries(record)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Bibl', class:'col-md-1') +
                            content_tag(:td, 'Oper', class:'col-md-1') +
                            content_tag(:td, 'Data inserimento', class:'col-md-2') +
                            content_tag(:td, 'Numcopie', class:'col-md-1') +
                            content_tag(:td, 'Prezzo', class:'col-md-1') +
                            content_tag(:td, 'Budget', class:'col-md-1') +
                            content_tag(:td, 'DataOrdine', class:'col-md-1') +
                            content_tag(:td, 'Status', class:'col-md-1') +
                            content_tag(:td, 'Fornitore', class:'col-md-1'), class:'warning')

    record.sbct_items.each do |r|
      supplier = r.sbct_supplier.nil? ? '' : r.sbct_supplier.to_label
      orders_lnk = r.order_date.nil? ? '' : link_to(r.order_date, orders_sbct_items_path(group_by:'title', order_date:r.order_date.strftime("%Y-%m-%d"),supplier_id:r.supplier_id))

      if r.clavis_library.siglabct.nil?
        library_name = r.clavis_library.to_label
        library_title = 'Senza sigla'
      else
        library_name = r.siglabib
        library_title = r.clavis_library.to_label
      end
      res << content_tag(:tr, content_tag(:td, link_to(library_name, edit_sbct_item_path(r.id), class:'btn btn-warning', target:'_blank'), title:library_title) +
                              content_tag(:td, r.created_by.nil? ? '-' : User.find(r.created_by).email) +
                              content_tag(:td, r.date_created.nil? ? '-' : r.date_created.to_s) +
                              content_tag(:td, r.numcopie) +
                              content_tag(:td, r.prezzo) +
                              content_tag(:td, r.sbct_budget.nil? ? '' : r.sbct_budget.label) +
                              content_tag(:td, orders_lnk) +
                              content_tag(:td, r.order_status) +
                              content_tag(:td, supplier), class:'success')
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-bordered')
  end

  def sbct_clavis_libraries(bbb)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-2') +
                            content_tag(:td, 'Data inventariazione', class:'col-md-2'), class:'warning')
    bbb.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['label'], ClavisItem.clavis_url(r['item_id']))) +
                              content_tag(:td, r['inventory_date'], class:'col-md-1'), class:'success')
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-bordered')
  end

  def sbct_presenti_in_clavis(esemplari)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Biblioteca', class:'col-md-2') +
                            content_tag(:td, 'Data inventariazione', class:'col-md-2') +
                            content_tag(:td, 'Stato', class:'col-md-2') +
                            content_tag(:td, 'Serie-Inventario', class:'col-md-2'), class:'warning')
    esemplari.each do |r|
      # inventory_date = r['inventory_date'].blank? ? to_date
      res << content_tag(:tr, content_tag(:td, link_to(r['label'], ClavisItem.clavis_url(r['item_id']))) +
                              content_tag(:td, (r['inventory_date'].nil? ? '(data mancante)' : r['inventory_date'].to_date)) +
                              content_tag(:td, r['item_status']) +
                              content_tag(:td, r['serieinv']), class:'success')
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-bordered')
  end

  def sbct_titles_users(users)
    res = []
    users.each do |r|
      res << content_tag(:tr, content_tag(:td, r.id) +
                              content_tag(:td, r.username) +
                              content_tag(:td, r.to_label) +
                              content_tag(:td, r.role_names) +
                              content_tag(:td, r.this_user_roles))
    end
    res=content_tag(:table, res.join.html_safe, class:'table table-striped')
  end
  
  def sbct_title_clavis_patrons(title)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Utente', class:'col-md-2') +
                            content_tag(:td, 'Data richiesta', class:'col-md-4') +
                            content_tag(:td, 'barcode', class:'col-md-4'), class:'success')

    title.clavis_patrons.each do |r|
      if r['patron_id'].blank?
        lnk="Lettore non trovato in Clavis: #{r.inspect}"
      else
        patron_label = "#{r['name']} #{r['lastname']}"
        lnk = link_to(patron_label, clavis_purchase_proposals_path(patron_id:r['patron_id']), target:'_blank')
      end
      res << content_tag(:tr, content_tag(:td, lnk, class:'col-md-2') +
                              content_tag(:td, r['data_richiesta_lettore'], class:'col-md-4') +
                              content_tag(:td, r['barcode'], class:'col-md-4'), class:'warning')
    end
    return '' if res.size==1
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def sbct_titles_breadcrumbs
    # return params.inspect
    links=[]
    links << link_to('Acquisti', '/cr')
    if params[:controller]=='sbct_lists' and ['report','show','index','new','upload','do_order'].include?(params[:action])
      if !params[:selection_mode].blank?
        links << link_to('Selezione', sbct_titles_path(:selection_mode=>'S', id_lista:params[:id]))
      else
        links << link_to("Liste d'acquisto", sbct_lists_path)
      end
      links << link_to(@sbct_list.label, sbct_list_path(@sbct_list)) if !@sbct_list.id.nil?
    end
    if params[:controller]=='sbct_budgets' and ['show','index'].include?(params[:action])
      links << link_to('Budgets', sbct_budgets_path)
    end
    if ['piurichiesti'].include?(params[:action])
      links << link_to('Titoli più richiesti', piurichiesti_sbct_titles_path)
    end

    if params[:controller]=='sbct_invoices' and ['show','index'].include?(params[:action])
      links << link_to('Fatture', sbct_invoices_path)
      links << link_to(@sbct_invoice.to_label, sbct_invoice_path) if !@sbct_invoice.nil?
    end

    if params[:controller]=='sbct_items'
      if params[:action]=='orders'
        links << link_to('Ordini', orders_sbct_items_path)
      else
        links << link_to('Copie', sbct_items_path)
      end
    end
    
    if params[:controller]=='sbct_suppliers' and ['show','index'].include?(params[:action])
      links << link_to('Fornitori', sbct_suppliers_path)
      links << link_to(@sbct_supplier.to_label, sbct_supplier_path) if !@sbct_supplier.nil?
    end

    if params[:controller]=='sbct_titles' and ['index','show'].include?(params[:action])
      if !@sbct_list.nil?
        if !params[:id_lista].blank?
          links << link_to("Liste d'acquisto", sbct_lists_path)
        else
          links << link_to('Titoli', sbct_titles_path)
        end
        # links << link_to(@sbct_list.to_label, sbct_titles_path(id_lista:@sbct_list.id, :page=>params[:page], :selection_mode=>params[:selection_mode]))
        links << link_to(@sbct_list.to_label, sbct_list_path(@sbct_list))
      end

      if !params[:selection_mode].blank?
        id_lista = @sbct_list.nil? ? params[:id_lista] : @sbct_list.id
        links << link_to('Selezione', sbct_titles_path(:selection_mode=>'S', id_lista:id_lista))
      else
        if !params[:id_lista].blank?
          # links << link_to("Liste d'acquisto", sbct_lists_path)
        else
          links << link_to('Titoli', sbct_titles_path)
        end
      end
    end
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

end
