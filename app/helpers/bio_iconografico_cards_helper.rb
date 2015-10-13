module BioIconograficoCardsHelper
  def bio_iconografico_cards_list(records)
    r=[]
    records.each do |c|
      r << bio_iconografico_cards_table_row(c)
    end
    content_tag(:table, r.join("\n").html_safe)
  end

  def bio_iconografico_cards_table_row(record,add_image=false)
    r=[]
    # link_clavis=record.authority_id.nil? ? '' : link_to("Clavis:#{record.authority_id} (#{record.authority_type})",ClavisAuthority.clavis_url(record.authority_id), :target=>'_new')
    r << content_tag(:tr,
                     content_tag(:td, record.numero_scheda) +
                     content_tag(:td, link_to(record.intestazione, edit_bio_iconografico_card_path(record), remote:false)) +
                     content_tag(:td, record.filename),
                     :id=>record.id)
    r.join.html_safe
  end

  def bio_iconografico_cards_menu_orizzontale
    r=[]
    links=[['Cerca',bio_iconografico_cards_path]]
    BioIconograficoCard.lettere.each do |l|
      links << [l,bio_iconografico_cards_path(:lettera=>l)]
    end
    links.each do |v|
      t,l=v
      lnk=link_to(t,l)
      r << content_tag(:li, lnk)
    end
    content_tag(:ul, r.join.html_safe)
  end


end
