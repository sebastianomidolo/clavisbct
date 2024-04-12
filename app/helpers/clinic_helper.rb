# coding: utf-8
module ClinicHelper
  def clinic_breadcrumbs
    # return params.inspect
    links=[]
    links << link_to('Clinica', '/clinic')
    links << link_to(params[:rep].capitalize, params[:rep]) if !params[:rep].blank?
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
        
  end

  def clinic_scarto(records)
    res=[]
    res << content_tag(:tr, content_tag(:td, 'Classe', class:'col-md-1') +
                            content_tag(:td, 'Descrizione', class:'col-md-1') +
                            content_tag(:td, 'AE', class:'col-md-1', title:'Anno edizione') +
                            content_tag(:td, 'UP', class:'col-md-1', title:'Anno ultimo prestito') +
                            content_tag(:td, 'EditionDate', class:'col-md-1') +
                            content_tag(:td, 'Collocazione', class:'col-md-1') +
                            content_tag(:td, 'UltimoPrestito', class:'col-md-1') +
                            content_tag(:td, 'AnniPrestito', class:'col-md-1') +
                            content_tag(:td, 'Titolo', class:'col-md-6'), class:'success')

    records.each do |r|
      lnk = link_to(r['title'], ClavisItem.clavis_url(r['item_id']))
      if r['anni_prestito'].nil?
        prestiti="mai prestato"
      else
        prestiti="#{r['anni_prestito'].split(',').join(', ')} (#{r['prestiti']})"
      end
      if r['copia_unica'] == 't'
        row_class = 'warning'
        prestiti << "<br/><b>Copia unica sul sistema</b>"
      else
        row_class = 'normal'
      end

      res << content_tag(:tr, content_tag(:td, r['classe']) +
                              content_tag(:td, r['descrizione']) +
                              content_tag(:td, r['edition_age']) +
                              content_tag(:td, r['anni_da_ultimo_prestito']) +
                              content_tag(:td, r['edition_date']) +
                              content_tag(:td, r['colloc_stringa']) +
                              content_tag(:td, r['ultimo_prestito']) +
                              content_tag(:td, r['copia_unica']) +
                              content_tag(:td, prestiti.html_safe) +
                              content_tag(:td, lnk), class:row_class)
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end

  def clinic_riepilogo_patrimonio(records)
    res=[]
    prm = "library=#{params[:library]}&onlyfc=#{params[:onlyfc]}&item_status=#{params[:item_status]}&loan_class=#{params[:loan_class]}&year=#{params[:year]}&item_media=#{params[:item_media]}&pubblico=#{params[:pubblico]}&genere=#{params[:genere]}&loans=#{params[:loans]}"

    # prm = "library=#{params[:library]}&onlyfc=#{params[:onlyfc]}&item_status=#{params[:item_status]}&loan_class=#{params[:loan_class]}&year=#{params[:year]}&item_media=#{params[:item_media]}&pubblico=#{params[:pubblico]}&genere=#{params[:genere]}&loans=#{params[:loans]}&statcol=#{params[:statcol]}"

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
    "Ci sono #{records.size} possibilità"
    res=[]
    records.each do |r|
      txt = r.description.blank? ? 'accedi' : r.description
      res << content_tag(:tr, content_tag(:td, r.reparto) +
                              content_tag(:td, r.azione) +
                              content_tag(:td, link_to(txt, "/clinic/#{r.reparto}/#{r.azione}", class:'btn btn-success')))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')

  end

  def clinic_check_collocation(records)
    res=[]
    records.each do |r|
      manif = r.manifestation_id.nil? ? 'fuoricat' : link_to(r.manifestation_id, ClavisManifestation.clavis_url(r.manifestation_id), title:'manifestation', target:'manifestation')
      if r.topografico=='f'
        lnk = link_to(r.item_id, r, target:'_new', title:'item')
      else
        lnk = link_to(r.item_id, extra_card_path(r.item_id), target:'_new', title:'topografico')
      end
      # lnk = link_to(r.item_id, r, target:'_new', title:'item')
      res << content_tag(:tr, content_tag(:td, r.statcol, class:'col-md-2') +
                              content_tag(:td, lnk, class:'col-md-2') +
                              content_tag(:td, manif, class:'col-md-2') +
                              content_tag(:td, link_to(r.colloc_stringa,r.clavis_url(:edit), target:'_new',class:'btn btn-warning'), class:'col-md-3') +
                              content_tag(:td, r.item_status_label, class:'col-md-5'))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
    content_tag(:div , content_tag(:div, res, class: 'panel-body'), class: 'panel panel-default table-responsive')
  end


  
end
