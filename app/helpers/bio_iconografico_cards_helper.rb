module BioIconograficoCardsHelper
  def bio_iconografico_cards_list(records)
    r=[]
    records.each do |c|
      r << bio_iconografico_cards_table_row(c)
    end
    content_tag(:table, r.join("\n").html_safe, class:'table')
  end

  def bio_iconografico_cards_table_row(record)
    r=[]
    if can? :manage, BioIconograficoCard
      r << content_tag(:tr,
                       content_tag(:td, record.numero_scheda) +
                       content_tag(:td, link_to(record.intestazione, bio_iconografico_card_path(record), remote:false) + "<br/>#{record.filename}".html_safe) +
                       content_tag(:td, link_to(bio_iconografico_card_image(record),
                                                edit_bio_iconografico_card_path(record)), style:'width:70%'),
                       :id=>record.id)
    else
      r << content_tag(:tr,
                       content_tag(:td, record.numero_scheda) +
                       content_tag(:td, link_to(record.intestazione, bio_iconografico_card_path(record), remote:false)) +
                       content_tag(:td, link_to(bio_iconografico_card_image(record),
                                                edit_bio_iconografico_card_path(record)), style:'width:70%'),
                       :id=>record.id)
    end
    r.join.html_safe
  end

  def bio_iconografico_cards_editable_list(records)
    r=[]
    records.each do |c|
      r << bio_iconografico_cards_editable_row(c)
    end
    content_tag(:table, r.join("\n").html_safe, class:'table')
  end

  def bio_iconografico_cards_editable_row(record)
    r=[]
    if can? :numera, BioIconograficoCard
      bip=best_in_place(record, :numero, ok_button:'Salva', cancel_button:'Annulla',
                        ok_button_class:'btn btn-success',
                        class:'btn btn-default',
                        skip_blur:false,
                        html_attrs:{size:4})
      bip_lettera=best_in_place(record, :lettera, ok_button:'Salva', cancel_button:'Annulla',
                                ok_button_class:'btn btn-success',
                                class:'btn btn-default',
                                skip_blur:false,
                                html_attrs:{size:1})
    else
      bip = record.numero
      bip_lettera = record.lettera
    end
      
    r << content_tag(:tr,
                     content_tag(:td, "#{bip_lettera}<br/>#{bip}".html_safe, style:'width:30%')+
                     content_tag(:td, link_to(bio_iconografico_card_image(record),
                                             bio_iconografico_card_path(record)), style:'width:70%'),
                     :id=>"edit_#{record.id}")
    r.join.html_safe
  end

  def bio_iconografico_card_image(record)
    image_tag(bio_iconografico_card_path(record, :format=>'jpg', :size=>'300x300'))
  end

  def bio_iconografico_cards_namespaces
    res = []
    BioIconograficoCard.namespaces.each do |n|
      if n.first.to_s == params[:namespace]
        res << content_tag(:b, n.last)
      else
        res << link_to(n.last, bio_iconografico_cards_path(namespace:n.first))
      end
    end
    res
  end

  def bio_iconografico_cards_menu_orizzontale
    r=[]
    links=[['Cerca',bio_iconografico_cards_path(namespace:params[:namespace])]]
    BioIconograficoCard.lettere.each do |l|
      links << [l,bio_iconografico_cards_path(lettera:l,namespace:params[:namespace])]
    end
    links.each do |v|
      t,l=v
      lnk=link_to(t,l)
      r << content_tag(:li, lnk)
    end
    content_tag(:ul, r.join.html_safe)
  end


end
