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
                     content_tag(:td, link_to(bctcard_image(record), bctcard_path(record, :topic_id=>params[:topic_id])), style:'width:70%'),
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

  def bctcards_breadcrumbs
    # return "controller: #{params[:controller]} / action: #{params[:action]} - #{params.inspect}"
    links=[]
    links << link_to('Biblioteche e archivi digitali', 'https://bct.comune.torino.it/sedi-orari/centrale/biblioteche-e-archivi-digitali')
    links << link_to('Repertori dal passato della Biblioteca civica', 'https://bct.comune.torino.it/repertori-dal-passato-della-biblioteca-civica')
    case params[:namespace]
    when 'bioico'
      links << link_to('Repertorio bio-iconografico', 'https://bct.comune.torino.it/repertorio-bio-iconografico')
    when 'cattor'
      links << link_to('Catalogo Torino', 'https://bct.comune.torino.it/catalogo-torino')
    when 'catarte'
      links << link_to('Catalogo Arte', 'https://bct.comune.torino.it/catalogo-arte')
    end

    if params[:controller]=='bctcards' and params[:action]=='index' and !params[:topic_id].blank?
      links << link_to('Ricerca', "/bctcards?namespace=#{params[:namespace]}")
    end
    if params[:controller]=='bctcards' and params[:action]=='show'
      links << link_to('Ricerca', "/bctcards?namespace=#{params[:namespace]}")
      lettera=params[:lettera]
      if !lettera.blank?
        links << link_to("Lettera #{lettera}", "/bctcards?namespace=#{params[:namespace]}&lettera=#{lettera}")
      end
    end

    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

  def bctcard_browse(record,params)
    p = record.browse_object('prev',params)
    n = record.browse_object('next',params)
    lnks = []
    if !p.nil?
      lnks << link_to('first', bctcard_path(record.browse_object('first',params)))
      lnks << link_to('prev', bctcard_path(p))
    else
      lnks << 'first'
      lnks << 'prev'
    end
    if !n.nil?
      lnks << link_to('next', bctcard_path(n))
      lnks << link_to('last', bctcard_path(record.browse_object('last',params)))
    else
      lnks << 'next'
      lnks << 'last'
    end
    " [#{lnks.join('|')}]".html_safe
    end


  

end
