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
      patron_path="http://sbct.comperio.it/index.php?page=Circulation.PatronViewPage&id=#{r.patron.id}"
      patron_path=clavis_purchase_proposals_path(patron_id:r.patron_id)
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
      res << content_tag(:tr, content_tag(:td, r.proposal_date.to_date) +
                         content_tag(:td, link_to(r['title'], lnk) + "<br/>#{notes}".html_safe) +
                         content_tag(:td, r.status_label) +
                         tv.join.html_safe +
                         content_tag(:td, link_to(r.patron.to_label, patron_path, target:'_blank')))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end
  
  def clavis_purchase_proposal_show(record)
    record.inspect
  end

end
