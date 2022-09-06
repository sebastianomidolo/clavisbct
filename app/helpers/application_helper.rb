module ApplicationHelper

  def open_div(id)
    %Q{<div id="#{id}">}.html_safe
  end

  def build_link(base)
    lnk=base
    reqfrom=params[:reqfrom]
    reqpath=params[:reqpath]
    if !reqfrom.blank?
      base.sub!(/^\//,'')
      base.sub!("?", '&')
      # lnk="http://#{reqfrom.split('?').first}?resource=#{base}"
      # lnk="#{reqfrom.split('?').first}?resource=#{base}"
      lnk="#{reqfrom}#{reqpath}?resource=#{base}"
    end
    lnk
  end

  def access_control_key
    DngSession.access_control_key(params,request)
  end

  def will_paginate_wrapper(target)
    x=will_paginate target
    return '' if x.nil?
    reqfrom=params[:reqfrom]
    reqpath=params[:reqpath]
    x.gsub!("/#{target.model_name.plural}?", "#{reqfrom}#{reqpath}?") if !reqfrom.blank?
    x.html_safe
  end

  def link_current_params(text,url,params={})
    prm=[]
    params.keys.each do |p|
      next if ['id','utf8','action','controller','ok_library_id','sbct_title'].include?(p)
      prm << "#{p}=#{params[p]}"
    end
    concat_char = url.index('?').nil? ? '?' : '&'
    url << concat_char << prm.join('&')
    link_to(text, url)
  end

  def hidden_params(params)
    prm=[]
    params.keys.each do |p|
      next if ['id','utf8','action','controller','authenticity_token'].include?(p)
      # prm << "hidden_field_tag('#{p}', #{params[p]})"
      prm << hidden_field_tag(p, params[p])
    end
    prm.join("\n").html_safe
  end

  
end
