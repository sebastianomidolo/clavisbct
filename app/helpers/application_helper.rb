module ApplicationHelper

  def open_div(id)
    %Q{<div id="#{id}">}.html_safe
  end

  def build_link(base)
    lnk=base
    reqfrom=params[:reqfrom]
    if !reqfrom.blank?
      base.sub!(/^\//,'')
      base.sub!("?", '&')
      lnk="http://#{reqfrom.split('?').first}?resource=#{base}"
    end
    lnk
  end

  def access_control_key
    dng = DngSession.find_from_params(params)
    return nil if dng.nil?
    dng.generate_ac
  end

end
