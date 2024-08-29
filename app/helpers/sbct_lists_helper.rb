# coding: utf-8
module SbctListsHelper

  def sbct_lists_index(records)
    res=[]
    lnk_locked = []

    lnk_locked << link_to("Aperta", sbct_lists_path(locked:false))
    lnk_locked << link_to("Chiusa", sbct_lists_path(locked:true))
    lnk_locked = lnk_locked.join('/').html_safe
    #res << content_tag(:tr, content_tag(:td, 'Nome della lista', class:'col-md-3') +
    #                        content_tag(:td, '(Meta)Budget', class:'col-md-3', title:'Nel caso di acquisti MiC si parla di meta-budget in quanto ogni biblioteca ha il proprio budget e tutti insieme costituiscono un meta-budget') +
    #                        content_tag(:td, '', class:'col-md-1') +
    #                        content_tag(:td, lnk_locked, class:'col-md-1') +
    #                        content_tag(:td, 'Titoli', class:'col-md-1') +
    #                        content_tag(:td, 'ParentList', class:'col-md-3'), class:'success')

    res << content_tag(:tr, content_tag(:td, 'Liste', class:'col-md-3'), class:'success')

    records.each do |r|
      next if r.owner_id == current_user.id or r.hidden==true
      lnk = link_to(r.label, sbct_list_path(r.id_lista,current_title_id:params[:current_title_id],req:params[:req]))
      blink = r.budget_label.blank? ? '-' : link_to(r.budget_label, sbct_budgets_path(budget_label:r.budget_label),target:'_blank')

      res << content_tag(:tr, content_tag(:td, lnk))
      next
      # Vecchiume da eliminare:
      parent_lnk = r.parent_list_label.blank? ? '' : link_to(r.parent_list_label, sbct_list_path(r.parent_id))
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, blink) +
                              content_tag(:td, r.tipo_titolo) +
                              content_tag(:td, r.locked == true ? 'chiusa' : 'aperta') +
                              content_tag(:td, r.cnt) +
                              content_tag(:td, parent_lnk))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sbct_list_index(sbct_list, records, table_title='')
    return '' if records.size==0
    res = []
    res << content_tag(:tr, content_tag(:td, 'File di origine', class:'col-md-2') +
                            content_tag(:td, 'Data di caricamento', class:'col-md-2') +
                            content_tag(:td, 'Numero titoli', class:'col-md-1'), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.original_filename, sbct_titles_path(id_lista:sbct_list,original_filename:r.original_filename))) +
                              content_tag(:td, r.date_created.to_date) +
                              content_tag(:td, r.count))
    end
    table_title + content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_private_lists(records, table_title='')
    return '' if records.size==0
    res = []
    res << content_tag(:tr, content_tag(:td, 'Lista', class:'col-md-2') +
                            content_tag(:td, 'Privata', class:'col-md-1') +
                            content_tag(:td, 'Sola lettura', class:'col-md-1') +
                            content_tag(:td, 'Caricamenti', class:'col-md-1') +
                            content_tag(:td, '', class:'col-md-1'), class:'success')
    records.each do |r|
      lnk = link_to(r.label, sbct_list_path(r.id_lista,current_title_id:params[:current_title_id]))
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, (r.hidden==false ? 'no' : 'sì')) +
                              content_tag(:td, (r.locked==false ? 'no' : 'sì')) +
                              content_tag(:td, (r.allow_uploads==false ? 'no' : 'sì')))
    end
    %Q{#{table_title}#{content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')}}.html_safe
  end

  def sbct_list_descendants_index(sbct_list)
    lists = sbct_list.descendants_index(current_user)
    return if lists.size==0
    res = []
    prec_level = 0
    lists.each do |r|
      lvl = prec_level - r.level.to_i
      if r.level.to_i > prec_level
        res << "<ul>" 
        prec_level = r.level.to_i
      else
        while lvl > 0
          res << "</ul>"
          # res << content_tag(:li, "rientro")
          lvl -= 1
        end
        prec_level = r.level.to_i
      end
      conteggio = r.count.to_i==0 ? '' : "#{r.count} titoli"
      conteggio = link_to(conteggio, sbct_titles_path(id_lista:r,norecurs:1), class:'btn btn-success') if !conteggio.blank?
      next if r.id_lista.nil?
      res << content_tag(:li, "#{link_to(r.label, sbct_list_path(r,req:params[:req],current_title_id:params[:current_title_id]))} #{conteggio}".html_safe)
    end
    content_tag(:div, res.join.html_safe)
  end

  def sbct_list_mass_assign_titles(sbct_list,user)
    lists = sbct_list.descendants_index(user)
    res = []
    prec_level = 0
    lists.each do |list|
      lvl = prec_level - list.level.to_i
      if list.level.to_i > prec_level
        res << "<ul>" 
        prec_level = list.level.to_i
      else
        while lvl > 0
          res << "</ul>"
          lvl -= 1
        end
        prec_level = list.level.to_i
      end
      res << content_tag(:li, button_to(list.to_label, mass_assign_titles_sbct_list_path(list)))
    end
    content_tag(:div, res.join("\n").html_safe)
  end
  
  def sbct_list_add_remove_title(sbct_list,current_title,user)
    liste_attuali=current_title.sbct_lists.collect {|i| i.id}
    lists = sbct_list.descendants_index(user)
   
    res = []
    prec_level = 0
    lists.each do |list|
      lvl = prec_level - list.level.to_i
      if list.level.to_i > prec_level
        res << "<ul>" 
        prec_level = list.level.to_i
      else
        while lvl > 0
          res << "</ul>"
          lvl -= 1
        end
        prec_level = list.level.to_i
      end
      # res << content_tag(:li, "#{link_to(list.label, sbct_list_path(r,req:params[:req],current_title_id:params[:current_title_id]))}".html_safe)

      msg = liste_attuali.include?(list.id) ? 'togli' : 'metti'
      method = liste_attuali.include?(list.id) ? 'delete' : 'post'
      #res << content_tag(:li, link_to("#{list.label} (attuali: #{liste_attuali.join(',')} #{msg} nella lista #{list.id})".html_safe,
      #                                title_sbct_list_path(list.id, id_titolo:current_title), method:method, remote:true), id:"list_#{list.id}")

      res << content_tag(:li, sbct_list_add_remove_row(list,current_title,liste_attuali), id:"list_#{list.id}")

    end
    confirm_btn = link_to('Conferma assegnazioni', sbct_title_path(current_title), class:'btn btn-success')
    # content_tag(:span, "#{sbct_list.label} ".html_safe) + link_to('Conferma assegnazioni', sbct_title_path(current_title), class:'btn btn-success') + content_tag(:div, res.join("\n").html_safe) + link_to('Conferma', sbct_title_path(current_title), class:'btn btn-success')
    v = res.size > 16 ? confirm_btn : ''
    # content_tag(:span, "#{header_label} ".html_safe) + confirm_btn + content_tag(:div, res.join("\n").html_safe) + v
    content_tag(:span, '&nbsp;'.html_safe, class:'col-md-4') + confirm_btn + content_tag(:div, res.join("\n").html_safe) + v
  end

  def sbct_list_add_remove_row(sbct_list,sbct_title,liste_attuali)
    if liste_attuali.include?(sbct_list.id)
      msg = "togli dalla lista"
      method = 'delete'
      css = 'success'
    else
      msg = "aggiungi alla lista"
      method = 'post'
      css = 'warning'
    end
    infotxt = sbct_list.hidden ? ' (privata)' : ''
    content_tag(:span,
                link_to("#{sbct_list.label}".html_safe,
                        title_sbct_list_path(sbct_list.id, id_titolo:sbct_title), title:msg, method:method, remote:true), class:"label label-#{css}") + infotxt
  end
  
  def sbct_list_toc(sbct_list, records, table_title='')
    return '' if records.size==0
    res = []
    res << content_tag(:tr, content_tag(:td, 'Reparto', class:'col-md-2') +
                            content_tag(:td, 'Sottoreparto', class:'col-md-2') +
                            content_tag(:td, 'Numero titoli', class:'col-md-1'), class:'success')
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.reparto, sbct_titles_path("sbct_title[titolo]":"reparto:#{r.reparto}",id_lista:sbct_list.id))) +
                              content_tag(:td, link_to(r.sottoreparto, sbct_titles_path("sbct_title[titolo]":"sottoreparto:#{r.sottoreparto}",id_lista:sbct_list.id))) +
                              content_tag(:td, r.count))
    end
    table_title + content_tag(:table, res.join("\n").html_safe, class:'table table-condensed')
  end

  def sbct_lists_assign(sbct_title,user)
    l = nil
    if user.role?(['AcquisitionManager','AcquisitionStaffMember'])
      # Da modificare in modo che la lista da cui partire venga trovata con un criterio logico
      # e non con un id specifico come avviene adesso:
      l = SbctList.find(5119)
    end
    l = user.sbct_acquisition_librarian_toplist if user.role?('AcquisitionLibrarian')
    return content_tag(:div, "nessuna lista trovata per <b>#{user.email}</b>".html_safe) if l.nil?
    content_tag(:div, sbct_list_add_remove_title(l,sbct_title,user))
  end

  def sbct_lists_mass_assign(user)
    l = nil
    if user.role?(['AcquisitionManager','AcquisitionStaffMember'])
      # Da modificare in modo che la lista da cui partire venga trovata con un criterio logico
      # e non con un id specifico come avviene adesso:
      l = SbctList.find(5119)
    end
    l = user.sbct_acquisition_librarian_toplist if user.role?('AcquisitionLibrarian')
    return content_tag(:div, "nessuna lista trovata per <b>#{user.email}</b>".html_safe) if l.nil?
    content_tag(:div, sbct_list_mass_assign_titles(l,user))
  end

  def sbct_lists_mass_remove_titles(title_ids,user)
    l = nil
    if user.role?('AcquisitionLibrarian')
      l = user.sbct_acquisition_librarian_toplist
    else
      if user.role?(['AcquisitionManager','AcquisitionStaffMember'])
        l = SbctList.find(5119)
      end
    end
    return content_tag(:div, "nessuna lista trovata per <b>#{user.email}</b>".html_safe) if l.nil?    
    sql = l.sql_for_descendants_index(user, title_ids)
    content_tag(:pre, sql)

    lists = l.descendants_index(user, title_ids)
    res = []
    res << "<ul>" 
    lists.each do |list|
      html_for_form = %Q{<form method="post" action=#{mass_remove_titles_sbct_list_path(list)} class="button_to">
           <button type="submit">#{list.to_label}</button>
#{hidden_field_tag(request_forgery_protection_token.to_s, form_authenticity_token)}
          <input type="hidden" name="title_ids" value="#{title_ids.join(',')}"></form>}
       res << content_tag(:li, html_for_form.html_safe + "(#{list.count} titoli in #{link_to(list.order_sequence.gsub('_', '. '), sbct_titles_path(id_lista:list.id,tinybox:true), target:'new')})".html_safe)
    end
    res << "</ul>" 
    return content_tag(:div, res.join("\n").html_safe) if res!=[]
    "Nessuno dei titoli in tinybox appartiene a liste"
  end
  
end
  
