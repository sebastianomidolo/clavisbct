# lastmod 20 febbraio 2013

module ClavisIssueHelper
  def clavis_issue_list(manifestation)
    r=[]
    manifestation.ultimi_fascicoli.each do |i|
      r << content_tag(:tr, content_tag(:td, i.issue_number) +
                       content_tag(:td, i.issue_year))
    end
    content_tag(:table, r.join.html_safe)
  end
  def clavis_issues_show(issues)
    r=[]
    imgtemplate=%Q{<div class="cover-wrapper">
<a class="cover" property="url" href="opac/detail/view/sbct:catalog:__MANIFESTATION__" title="__TITLE__">
    <div class="cover-overlay adjust-size"> </div>
    <div class="cover-border left"> </div>
    <img title="__TITLE__"
        src="https://sbct.comperio.it/index.php?file=__NUMFILE__"
        alt="__TITLE__"
        property="image"
    /></a></div>}
    prec_mid=''
    issues.each do |i|
      next if i.attachment_id.nil?
      next if prec_mid==i.manifestation_id
      prec_mid=i.manifestation_id
      img=imgtemplate.sub("__NUMFILE__", i.attachment_id)
      img=img.sub("__MANIFESTATION__", i.manifestation_id.to_s)
      img=img.gsub("__TITLE__", i.title)
      info="#{i.title}<br/>Numero <b>#{i.issue_number}</b><br>Arrivato il <b>#{i.issue_arrival_date.to_date}</b><br/>Collocazione: <b>#{i.collocation}</b>"
      notes={}
      cnt=0
      i.er_resource_notes.split('%%%').each do |n|
        notes[cnt]=n
        cnt+=1
      end
      cnt=0
      i.er_resource_urls.split('%%%').each do |u|
        lnk = (u=~/^http/).nil? ? "http://#{u}" : u 
        info << "<br/><b>#{link_to(lnk,lnk)}</b>"
        info << " (#{notes[cnt]})" if !notes[cnt].blank? 
        cnt+=1
      end
      r << content_tag(:tr, content_tag(:td, content_tag(:span, img.html_safe), style:'width: 10%') +
                       content_tag(:td,info.html_safe, style:'width: 30%'))
    end
    content_tag(:table, r.join.html_safe, {class: 'table table-striped'})
  end

end
