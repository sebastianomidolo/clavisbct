module BioIconograficoTopicsHelper

  def bio_iconografico_topics_list(records)
    r=[]
    records.each do |c|
      r << bio_iconografico_topics_table_row(c)
    end
    content_tag(:table, r.join("\n").html_safe)
  end

  def bio_iconografico_topics_table_row(record)
    r=[]
    r << content_tag(:tr,
                     content_tag(:td, link_to(record.intestazione, bio_iconografico_topic_path(record), remote:false)) +
                     content_tag(:td, record.count),
                     :id=>record.id)
    r.join.html_safe
  end

  def bio_iconografico_topics_menu_orizzontale(css_class='')
    r=[]
    links=[['Cerca',bio_iconografico_cards_path]]
    BioIconograficoCard.lettere.each do |l|
      links << [l,bio_iconografico_topics_path(:lettera=>l)]
    end
    links.each do |v|
      t,l=v
      lnk=link_to(t,l)
      r << content_tag(:li, lnk)
    end
    # content_tag(:ul, r.join.html_safe, class:"nav navbar-nav")
    content_tag(:ul, r.join.html_safe, class:css_class)
  end
end
