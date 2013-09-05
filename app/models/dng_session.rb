class DngSession < ActiveRecord::Base
  attr_accessible :patron_id, :client_ip, :login_time

  belongs_to :patron, :foreign_key=>:patron_id, :class_name=>'ClavisPatron'

  def generate_ac(ip=nil)
    ip=self.client_ip if ip.nil?
    Digest::SHA2.hexdigest([ip,self.login_time].join(','))
  end

  def check_service(service_name,params,request,authorizable_object=nil)
    if (self.patron.opac_username != params[:dng_user] or
        self.client_ip != DngSession.format_client_ip(request))
      return false
    end
    case service_name
    when 'talking_book'
      return self.patron.autorizzato_al_servizio_lp
    when 'download_pdf'
      # In this case, authorizable_object is the instance of ClavisManifestion we are going to check
      # for authorization
      return self.patron.autorizzato_download_pdf(authorizable_object)
    end
    false
  end

  def expired?
    (Time.now-self.login_time).to_i > 3600 ? true : false
  end

  def DngSession.find_by_params_and_request(params,request)
    return nil if params[:dng_user].blank?
    user=DngSession.connection.quote(params[:dng_user].downcase)
    ip=DngSession.connection.quote(DngSession.format_client_ip(request))
    sql=%Q{SELECT s.* FROM dng_sessions s JOIN clavis.patron p USING(patron_id)
            WHERE p.opac_username=#{user} AND client_ip=#{ip} ORDER BY s.id desc LIMIT 1}
    logger.debug("DngSession.find_by_params_and_request =>\n#{sql}")
    DngSession.find_by_sql(sql).first
  end

  def DngSession.authenticate_from_params(params,request)
    return false if params[:ac].blank? or params[:dng_user].blank?
    dng=self.find_by_params_and_request(params,request)
    return false if dng.nil?
    ac=params[:ac]
    ip=DngSession.format_client_ip(request)
    ac_session=dng.generate_ac(ip)
    ac_session == ac
  end

  def DngSession.format_client_ip(request)
    [request.remote_ip, request.headers['REMOTE_ADDR']].uniq.join(', ')
  end

  def DngSession.access_control_key(params,request)
    dng = DngSession.find_by_params_and_request(params,request)
    return nil if dng.nil? or dng.expired?
    dng.generate_ac
  end

end
