# coding: utf-8
module SpItemsHelper
  def sp_item_show(record)
    res=[]
    style="margin-left: 20px"
    res << content_tag(:p, record.bibdescr.html_safe, style: 'font-size: 120%')
    res << content_tag(:p, "Collocazione: <b>#{record.collocazioni}</b>".html_safe,style: 'font-size: 120%') if !record.collocazioni.blank?
    res << content_tag(:div,
                       content_tag(:span, "Questa scheda è contenuta nella bibliografia: ", :style=>style) + 
                       content_tag(:span,
                                   link_to(record.sp_bibliography.title,
                                           build_link(sp_bibliography_path(record.sp_bibliography.id)))))

    if !record.thesection.blank?
      res << content_tag(:div,
                         content_tag(:span, "Sezione della bibliografia: ", :style=>style) + 
                         content_tag(:span,
                                     link_to(record.thesection,
                                             build_link(sp_section_path(record.sp_section,
                                                                        :number=>record.sp_section.number)))))
    end

    res << content_tag(:div, clavis_manifestation_opac_preview(record.clavis_manifestation)) if !record.clavis_manifestation.nil?

    res.join.html_safe
  end

  def sp_items_list_items(sp_items)
    res=[]
    sp_items.each do |i|
      res << content_tag(:tr, content_tag(:td,
                                          link_to(i.bibdescr,
                                                  build_link(sp_item_path(i)))) +
                         content_tag(:td, i.collciv))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def sp_items_ricollocati_a_scaffale_aperto(sp_items)
    res=[]
    sp_items.each do |i|
      res << content_tag(:tr, content_tag(:td,
                                          link_to(i.bibdescr, i.senza_parola_item_path,target:'_new'),
                                          style:'width:50%') +
                         content_tag(:td, i.ex_collocazione) +
                         content_tag(:td, i.section) +
                         content_tag(:td, i.collocation) +
                         content_tag(:td, i.bibliography_title))
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
  end

  def sp_item_clavis_info(sp_item)
    cm=sp_item.clavis_manifestation
    return 'non trovato in Clavis' if cm.nil?
    r=cm.collocazioni_e_siglebib_per_senzaparola
    info="collciv: #{r['collciv']}<br/>colldec: #{r['colldec']}<br/>sigle: #{r['sigle']}"
    content_tag(:div, clavis_manifestation_opac_preview(cm) +
                content_tag(:div, link_to('Clavis gestionale', cm.clavis_url(:show))) +
                content_tag(:div, info.html_safe) +
                clavis_manifestation_show_items(cm))
  end


end
