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
      if r.data_libri.nil?
        txt = r.label
      else
        txt = r.data_libri.to_s
        txt << " - #{r.label}" if !r.label.blank?
        # lnk = link_to(txt, sbct_titles_path(id_lista:r.id_lista))
      end
      lnk = link_to(txt, sbct_list_path(r.id_lista,current_title_id:params[:current_title_id]))
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
      res << content_tag(:li, "#{link_to(r.label, sbct_list_path(r,current_title_id:params[:current_title_id]))} #{conteggio}".html_safe)
      #      res << content_tag(:li, r.attributes)
      
    end
    # content_tag(:ol, res.join.html_safe)
    content_tag(:div, res.join.html_safe)
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

end
  
