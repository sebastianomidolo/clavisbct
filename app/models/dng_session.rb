class DngSession < ActiveRecord::Base
  attr_accessible :patron_id, :client_ip, :login_time

  belongs_to :patron, :foreign_key=>:patron_id, :class_name=>'ClavisPatron'

  def generate_ac(ip=nil)
    ip=self.client_ip if ip.nil?
    Digest::SHA2.hexdigest([ip,self.login_time].join(','))
  end

  def check_service(service_name,params,request,authorizable_object=nil)
    if (self.patron.opac_username.upcase != params[:dng_user].upcase or
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

  def log_session_id
    fd=File.open('/tmp/last_session_id', 'w')
    fd.write(self.id)
    fd.close
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

  def DngSession.google_drive_log
    config = Rails.configuration.database_configuration
    username=config[Rails.env]["google_drive_login"]
    passwd=config[Rails.env]["google_drive_passwd"]
    session = GoogleDrive.login(username, passwd)
    s=session.spreadsheet_by_title('Accessi a BCT opac')
    ws=s.worksheets.first
    ws.update_cells(1,1,[['ID sessione','IP address','Data accesso','ID Utente Clavis','Nome','Cognome','Classe Utente']])

    sql=%Q{SELECT s.*,p.name,p.lastname,p.loan_class
          FROM public.dng_sessions s JOIN clavis.patron p using(patron_id)
          ORDER BY s.id DESC limit 50;}
    res=DngSession.find_by_sql(sql)
    ws.update_cells(2,1,res.collect {|i| [i.id,i.client_ip,i.login_time.strftime('%Y-%m-%d %H:%M:%S'),i[:patron_id],i[:name],i[:lastname],i[:loan_class]]})
    ws.save
    
    ws=s.worksheets.last
    ws.update_cells(1,1,[['ID sessione','IP address','Data accesso','ID Utente Clavis','Nome','Cognome','Classe Utente']])
    sql=%Q{SELECT s.*,p.name,p.lastname,p.loan_class
          FROM public.dng_sessions s JOIN clavis.patron p using(patron_id)
          WHERE p.loan_class='@' ORDER BY s.id DESC limit 50;}
    res=DngSession.find_by_sql(sql)
    ws.update_cells(2,1,res.collect {|i| [i.id,i.client_ip,i.login_time.strftime('%Y-%m-%d %H:%M:%S'),i[:patron_id],i[:name],i[:lastname],i[:loan_class]]})
    ws.save
  end

end
