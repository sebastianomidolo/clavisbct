# coding: utf-8
module ClinicHelper
  def clinic_breadcrumbs
    # return params.inspect
    links=[]
    links << link_to('Officina dati', '/clinic')
    links << link_to(params[:rep].capitalize, params[:rep]) if !params[:rep].blank?
    links << link_to('Regole per lo scarto', discard_rules_path) if params[:controller]=='discard_rules'
    if params[:controller]=='clinic_actions'
      links << link_to('Azioni', clinic_actions_path)
      links << link_to(@clinic_action.to_label, clinic_action_path(@clinic_action)) if !@clinic_action.nil?
    end
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
        
  end

  def clinic_scarto(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Categoria', class:'col-md-1', title:'Secondo SMUSI') +
                            content_tag(:td, 'AE', class:'col-md-1', title:'Anno edizione') +
                            content_tag(:td, 'UP', class:'col-md-1', title:'Anno ultimo prestito') +
                            content_tag(:td, 'StatCol', class:'col-md-1') +
                            content_tag(:td, 'EditionDate', class:'col-md-1') +
                            content_tag(:td, 'Collocazione/ClassCode', class:'col-md-1') +
                            content_tag(:td, 'UltimoPrestito', class:'col-md-1') +
                            content_tag(:td, 'AnniPrestito', class:'col-md-1') +
                            content_tag(:td, 'AnniPrestitoTotale', class:'col-md-1', title:'cioè, in tutte le biblioteche BCT') +
                            content_tag(:td, 'Titolo', class:'col-md-6'), class:'success')

    records.each do |r|
      if r['anni_prestito'].nil?
        prestiti="copia mai prestata"
      else
        prestiti="#{r['anni_prestito'].split(',').join(', ')} (#{r['prestiti']})"
      end
      if r['anni_prestito_totale'].nil?
        prestiti_totale="mai prestato"
      else
        prestiti_totale="#{r['anni_prestito_totale'].split(',').join(', ')} (#{r['prestiti_totale']})"
      end
      
      if r.other_library_count == '0'
        row_class = 'warning'
        prestiti << "<br/><b>Copia unica sul sistema</b>" if !r.manifestation_id.nil?
      else
        row_class = 'normal'
      end

      begin
        if r.print_year > r.edition_date
          year = "#{r.edition_date}<br/><b>rist. #{r.reprint}</b>"
        else
          year = r.print_year
        end
      rescue
        # year = "edition_date: #{r.edition_date}<br/>print_year: #{r.print_year}"
        year = "data mancante"
      end
      inv_date = r.inventory_date.nil? ? '' : %Q{<br/><span title="Data accessionamento">#{r.inventory_date.to_date}</span>}.html_safe
      year << inv_date
      lnk = link_to(r['title'], ClavisItem.clavis_url(r['item_id']))

      if r.class_code.blank?
        collclass = r.colloc_stringa
      else
        collclass = "#{r.colloc_stringa}/<br/>#{r.class_code}"
      end
      collclass = 'NON PRESENTE' if collclass.nil?

      collclass << "<br/>#{r.other_library_labels}"

      
      #sprintf("%-3s", "6").gsub(' ', '0')
      #classe = r['classe']
      # classe = r.dr_classe_from.blank? ? '-' : sprintf("%-3s", r['classe']).gsub(' ', '0')
      classe = r.dr_classe
      res << content_tag(:tr, content_tag(:td, link_to("#{r.dr_descrizione}<br/>#{classe}".html_safe, discard_rule_path(r.dr_id))) +
                              content_tag(:td, r.dr_edition_age) +
                              content_tag(:td, r.dr_anni_da_ultimo_prestito) +
                              content_tag(:td, r.statcol) +
                              content_tag(:td, year.html_safe) +
                              content_tag(:td, collclass.html_safe) +
                              content_tag(:td, r.ultimo_prestito) +
                              content_tag(:td, prestiti.html_safe) +
                              content_tag(:td, prestiti_totale.html_safe) +
                              content_tag(:td, lnk), class:row_class)
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clinic_riepilogo_patrimonio(records)
    res=[]
    prm = "library_id=#{params[:library_id]}&onlyfc=#{params[:onlyfc]}&item_status=#{params[:item_status]}&loan_class=#{params[:loan_class]}&year=#{params[:year]}&item_media=#{params[:item_media]}&pubblico=#{params[:pubblico]}&genere=#{params[:genere]}&loans=#{params[:loans]}&piemonte=#{params[:piemonte]}&other_libraries=#{params[:other_libraries]}&statcol_error=#{params[:statcol_error]}&bib_type=#{params[:bib_type]}&bib_type_first=#{params[:bib_type_first]}&u100_pubblico=#{params[:u100_pubblico]}"

    res << content_tag(:tr, content_tag(:td, 'Pubblico', class:'col-md-1') +
                            content_tag(:td, 'StatCol', class:'col-md-1') +
                            content_tag(:td, 'Copie', class:'col-md-1') +
                            content_tag(:td, 'Prestiti', class:'col-md-7'), class:'success')
    
    cnt = cnt_prestiti = 0
    records.each do |r|
      cnt += r['count'].to_i
      cnt_prestiti += r['numprestiti'].to_i
      r['statcol'] = 'non assegnato' if r['statcol'].blank?
      if r['ghost_statcol'].blank?
        lnk = link_to(r['statcol'], "/clinic/stats/nonclassif?statcol=#{r['statcol']}&#{prm}", class:'btn btn-warning')
      else
        if r['statcol'] =~ /NonClassif/
          lnk = link_to(r['statcol'], "/clinic/stats/nonclassif?statcol=#{r['statcol']}&#{prm}", class:'btn btn-success')
        else
          lnk = link_to(r['statcol'], "/clinic/stats/nonclassif?statcol=#{r['statcol']}&#{prm}")
        end
      end
      res << content_tag(:tr, content_tag(:td, r['pubblico'], class:'col-md-1') +
                              content_tag(:td, lnk, class:'col-md-1') +
                              content_tag(:td, r['count'], class:'col-md-1') +
                              content_tag(:td, r['numprestiti'].to_i, class:'col-md-10'))
    end
    res << content_tag(:tr, content_tag(:td, '') +
                            content_tag(:td, '') +
                            content_tag(:td, cnt) +
                            content_tag(:td, cnt_prestiti))
    res << content_tag(:tr, content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, 'Copie', class:'col-md-1') +
                            content_tag(:td, 'Prestiti', class:'col-md-7'), class:'success')

    
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clinic_reception(records)
    # "Ci sono #{records.size} possibilità"
    res=[]
    records.each do |r|
      prms = r.azione == 'patrimonio' ? "?library_id=bct" : ''
      txt = r.description.blank? ? 'accedi' : r.description
      res << content_tag(:tr, content_tag(:td, r.reparto) +
                              content_tag(:td, r.azione) +
                              content_tag(:td, link_to(txt, "/clinic/#{r.reparto}/#{r.azione}#{prms}", class:'btn btn-success')))
    end
    res=content_tag(:table, res.join("\n").html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')

  end

  def clinic_check_collocation(records)
    res=[]
    records.each do |r|
      manif = r.manifestation_id.nil? ? 'fuoricat' : link_to(r.manifestation_id, ClavisManifestation.clavis_url(r.manifestation_id), title:'manifestation', target:'manifestation')
      if r.topografico=='f'
        lnk = link_to(r.title, r, target:'_new', title:'item')
      else
        lnk = link_to(r.item_id, extra_card_path(r.item_id), target:'_new', title:'topografico')
      end
      lbl = r.home_library.nil? ? '?' : r.home_library.to_label
      item_lnk=link_to(r.colloc_stringa,r.clavis_url(:edit), target:'_new',class:'btn btn-warning') + "<br/>#{lbl}".html_safe
      res << content_tag(:tr, content_tag(:td, r.statcol, class:'col-md-2') +
                              content_tag(:td, lnk, class:'col-md-2') +
                              content_tag(:td, manif, class:'col-md-2') +
                              content_tag(:td, item_lnk, class:'col-md-3') +
                              content_tag(:td, r.item_status_label, class:'col-md-5'))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def discard_rules_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Da', class:'col-md-1') +
                            content_tag(:td, 'A', class:'col-md-1') +
                            content_tag(:td, 'Descrizione', class:'col-md-6') +
                            content_tag(:td, 'Anni da data pubblicazione', class:'col-md-1') +
                            content_tag(:td, 'Anni da ultimo prestito', class:'col-md-1') +
                            content_tag(:td, 'SMUSI', class:'col-md-2'), class:'success')
    records.each do |r|
      descr = r.descrizione.blank? ? '[descrizione]' : r.descrizione
      res << content_tag(:tr, content_tag(:td, r.classe_from) +
                              content_tag(:td, r.classe_to) +
                              content_tag(:td, link_to(descr,edit_discard_rule_path(r))) +
                              content_tag(:td, r.edition_age) +
                              content_tag(:td, r.anni_da_ultimo_prestito) +
                              content_tag(:td, link_to(r.smusi, "/clinic/stats/patrimonio?dr_id=#{r.id}&smusi='S'")))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def clinic_actions_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Reparto', class:'col-md-1') +
                            content_tag(:td, 'Azione', class:'col-md-1') +
                            content_tag(:td, 'Descrizione', class:'col-md-6') +
                            content_tag(:td, 'Attivo', class:'col-md-1') +
                            content_tag(:td, 'SQL', class:'col-md-1'), class:'success')
    records.each do |r|
      descr = r.description.blank? ? '[descrizione]' : r.description
      res << content_tag(:tr, content_tag(:td, r.reparto) +
                              content_tag(:td, r.azione) +
                              content_tag(:td, link_to(descr,r)) +
                              content_tag(:td, r.attivo) +
                              content_tag(:td, r.sql.nil? ? 'no' : 'sì'))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end


end
