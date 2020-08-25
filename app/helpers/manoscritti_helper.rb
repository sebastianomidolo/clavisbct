module ManoscrittiHelper
  def manoscritto_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k, class:'col-sm-2') + content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def manoscritto_browse(record)
    p = record.browse_object('prev')
    n = record.browse_object('next')
    lnks = []
    if !p.nil?
      lnks << link_to('first', manoscritto_path(record.browse_object('first')))
      lnks << link_to('prev', manoscritto_path(p))
    else
      lnks << 'first'
      lnks << 'prev'
    end
    if !n.nil?
      lnks << link_to('next', manoscritto_path(n))
      lnks << link_to('last', manoscritto_path(record.browse_object('last')))
    else
      lnks << 'next'
      lnks << 'last'
    end
    " [#{lnks.join('|')}]".html_safe
  end


  def manoscritti_breadcrumbs
    # return "controller: #{params[:controller]} / action: #{params[:action]} - #{params.inspect}"
    links=[]
    links << link_to('Manoscritti', 'https://bct.comune.torino.it/manoscritti')
 
    if params[:controller]=='manoscritti' and params[:action]=='show'
      links << link_to('Catalogo', manoscritti_path)
    end
 
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

end
