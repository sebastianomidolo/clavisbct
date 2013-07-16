class DngSession < ActiveRecord::Base
  attr_accessible :patron_id, :client_ip, :login_time

  belongs_to :patron, :foreign_key=>:patron_id, :class_name=>'ClavisPatron'

  def generate_ac(ip=nil)
    ip=self.client_ip if ip.nil?
    Digest::SHA2.hexdigest([ip,self.login_time].join(','))
  end

  def check_service(service_name)
    puts self.patron_id
    if service_name=='talking_book'
      return true
    end
    false
  end

  # Da fare: controllare anche l'ora dell'ultimo accesso
  def DngSession.find_from_params(params)
    return nil if params[:dng_user].blank?
    user=DngSession.connection.quote(params[:dng_user].downcase)
    sql=%Q{SELECT s.* FROM dng_sessions s JOIN clavis.patron p USING(patron_id)
            WHERE p.opac_username=#{user} ORDER BY s.id desc}
    DngSession.find_by_sql(sql).first
  end

  def DngSession.authenticate_from_params(params,request)
    return false if params[:ac].blank? or params[:dng_user].blank?
    dng=self.find_from_params(params)
    return false if dng.nil?
    ac=params[:ac]
    ip=DngSession.format_client_ip(request)
    ac_session=dng.generate_ac(ip)
    ac_session == ac
  end

  def DngSession.format_client_ip(request)
    [request.remote_ip, request.headers['REMOTE_ADDR']].uniq.join(', ')
  end

end
