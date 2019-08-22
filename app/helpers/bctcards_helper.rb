module BctcardsHelper
  def bctcards_list(records)
    ns=BioIconograficoCard.namespaces
    r=[]
    records.each do |c|
      r << bctcards_table_row(c,ns)
    end
    content_tag(:table, r.join("\n").html_safe, class:'table')
  end

  def bctcards_table_row(record,ns)
    r=[]
    intestazione = (record.intestazione.blank? or record.intestazione.size==0) ? 'Intestazione mancante' : record.intestazione.html_safe
    r << content_tag(:tr,
                     content_tag(:td, intestazione) +
                     content_tag(:td, ns[record.namespace.to_sym]) +
                     content_tag(:td, link_to(bctcard_image(record), bctcard_path(record)), style:'width:70%'),
                     :id=>record.id)
    r.join.html_safe
  end

  def bctcard_image(record)
    image_tag(bctcard_path(record, :format=>'jpg', :size=>'300x300'))
  end

  def bctcards_namespaces(user=nil)
    res = []
    {
      :bioico=>"Repertorio bio-iconografico",
      :catarte=>"Catalogo Arte",
      :cattor=>"Catalogo Torino",
      nil => 'Tutti',
    }.each do |n|
      if n.first.to_s == params[:namespace]
        res << content_tag(:b, n.last)
      else
        res << link_to(n.last, bctcards_path(namespace:n.first))
      end
    end
    res
  end

  def bctcards_menu_orizzontale
    r=[]
    if params[:namespace].blank?
      return ''
    else
      links=[['Cerca',bctcards_path(namespace:params[:namespace])]]
      BioIconograficoCard.lettere.each do |l|
        links << [l,bctcards_path(lettera:l,namespace:params[:namespace])]
      end
    end
    links.each do |v|
      t,l=v
      lnk=link_to(t,l)
      r << content_tag(:li, lnk)
    end
    content_tag(:ul, r.join.html_safe)
  end


end
