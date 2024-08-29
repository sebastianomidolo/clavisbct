module ClavisPurchaseProposalsHelper

  def clavis_purchase_proposals_list(records)
    res=[]
    fields=[
            'author',
            'publisher',
            'year',
            'notes',
    ]
    fields=[
            'author',
            'year',
            'notes',
    ]


    res << content_tag(:tr, content_tag(:td, 'data', class:'col-md-1') +
                            content_tag(:td, 'titolo', class:'col-md-2') +
                            content_tag(:td, 'stato', class:'col-md-1') +
                            content_tag(:td, 'ean', class:'col-md-1') +
                            content_tag(:td, 'autore', class:'col-md-1') +
                            content_tag(:td, 'anno', class:'col-md-1') +
                            content_tag(:td, 'nota', class:'col-md-1') +
                            content_tag(:td, '-', class:'col-md-1') +
                            content_tag(:td, '-', class:'col-md-1') +
                            content_tag(:td, 'utente', class:'col-md-1'), class:'success')

    
    records.each do |r|
      lnk=clavis_purchase_proposal_path(r)
      tv=[]
      fields.each do |f|
        if f=='ean'
          value=r.send(f)
          if value.size < 10
            tv << content_tag(:td, value)
          else
            tv << content_tag(:td, link_to(value, sbct_titles_path("sbct_title[titolo]":value),target:'_acquisti'))
          end
        else
          tv << content_tag(:td, r.send(f))
        end
      end
      if !r.manifestation_id.nil?
        tv << content_tag(:td, link_to('Opac', ClavisManifestation.clavis_url(r.manifestation_id,:opac)))
      else
        tv << content_tag(:td, "-")
      end
      tv << content_tag(:td, "#{r.username}<br/>#{r.date_updated.to_date}".html_safe, title:"Aggiornata da #{r.username} il #{r.date_updated}")

      notes=r.librarian_notes

      if r.patron.nil?
        patron_label = "Utente #{r.patron_id} non presente in ClavisBCT a causa di un errore di importazione"
        patronpath=ClavisPatron.clavis_url(r.patron_id)
      else
        patron_label = r.patron.to_label
        patronpath=clavis_purchase_proposals_path(patron_id:r.patron_id)
      end
      status = r.status_label
#      if !r.home_library_id.nil?
#        status << "<br/>#{r.item_status_label}" if !r.item_status_label.nil?
#        if r.destbib.nil?
#          status << "<br/><span class='label label-warning' title='Data inventariazione (fuori circuito BCT)'>#{r.inventory_date}</span>" if !r.inventory_date.nil?
#        else
#          status << "<br/><span class='label label-success' title='Data inventariazione per biblioteca #{r.destbib}'>#{r.inventory_date}</span>" if !r.inventory_date.nil?
#        end
#      end
      # status=''
      r.item_status_label.split(',').each do |e|
        status << "<br/><span class='label label-success' title='Item status in Clavis'>#{e}</span>"
      end
      
      lnk_ean = r.id_titolo.nil? ? r.ean : link_to(r.ean, sbct_title_path(r.id_titolo), class:'btn btn-success')
      res << content_tag(:tr, content_tag(:td, r.proposal_date.to_date) +
                              content_tag(:td, link_to(r['title'], lnk) + %Q{<br/>#{notes}}.html_safe) +
                              content_tag(:td, status.html_safe) +
                              content_tag(:td, lnk_ean) +
                              tv.join.html_safe +
                              content_tag(:td, link_to(patron_label, patronpath, target:'_blank') + "<br/>#{r.patron.barcode}".html_safe))
    end
    content_tag(:table, res.join("\n").html_safe, class:'table table-striped')
  end
  
  def clavis_purchase_proposal_show(record)
    res=[]
    
    record.attribute_names.sort.each do |r|
      case r
      when 'status'
        dt=record.status_label
      when 'patron_id'
        dt=link_to(record.patron.to_label, record.patron_clavis_url, target:'_new')
        r="proposto da"
      when 'created_by'
        dt=nil
      else
        dt=record[r]
        # dt=nil if dt==0
      end
      next if dt.blank?
      res << content_tag(:tr, content_tag(:td, r) +
                              content_tag(:td, dt))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

end
