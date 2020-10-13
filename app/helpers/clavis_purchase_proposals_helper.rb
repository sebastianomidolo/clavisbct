module ClavisPurchaseProposalsHelper

  def clavis_purchase_proposals_list(records)
    res=[]
    fields=[
            'ean',
            'author',
            'publisher',
            'year',
            'notes',
           ]
    records.each do |r|
      lnk=clavis_purchase_proposal_path(r)
      tv=[]
      fields.each do |f|
        tv << content_tag(:td, r.send(f))
      end
      if !r.item_id.nil? and r.item_id>0
        tv << content_tag(:td, link_to('Vedi in Clavis', ClavisItem.clavis_url(r.item_id)))
      else
        tv << content_tag(:td, "-")
      end
      if !r.manifestation_id.nil?
        tv << content_tag(:td, link_to('Opac', ClavisManifestation.clavis_url(r.manifestation_id,:opac)))
      else
        tv << content_tag(:td, "-")
      end

      notes=r.librarian_notes

      if r.patron.nil?
        patron_label = "Utente #{r.patron_id} non presente in ClavisBCT a causa di un errore di importazione"
        patronpath=ClavisPatron.clavis_url(r.patron_id)
      else
        patron_label = r.patron.to_label
        patronpath=clavis_purchase_proposals_path(patron_id:r.patron_id)
      end
      res << content_tag(:tr, content_tag(:td, r.proposal_date.to_date) +
                         content_tag(:td, link_to(r['title'], lnk) + "<br/>#{notes}".html_safe) +
                         content_tag(:td, r.status_label) +
                         tv.join.html_safe +
                         content_tag(:td, link_to(patron_label, patronpath, target:'_blank')))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
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
      when 'ean'
        dt=nil if record[r]=='0'
      else
        dt=record[r]
        dt=nil if dt==0
      end
      next if dt.blank?
      res << content_tag(:tr, content_tag(:td, r) +
                              content_tag(:td, dt))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

end
