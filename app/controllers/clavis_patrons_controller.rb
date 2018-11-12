class ClavisPatronsController < ApplicationController
  load_and_authorize_resource only: [:wrong_contacts,:show]

  def user_checkin_notification
    user=params[:user]
    opac_secret=params[:pass]
    ip=params[:ip]

    p=ClavisPatron.find_by_opac_username_and_opac_enable_and_opac_secret(user.downcase,'1',opac_secret)
    if p.nil?
      @msg="NOT FOUND #{user} - #{opac_secret} - #{ip}"
    else
      # Da sostituire poi con: DngSession.format_client_ip(request)
      @client_ip=[request.remote_ip, request.headers['REMOTE_ADDR']].uniq.join(', ')
      # @client_ip=DngSession.format_client_ip(request)

      @hash_ip=Digest::SHA1.hexdigest(@client_ip)
      @msg="TROVATO #{p.opac_username} #{p.lastname}\n ip:#{ip}\nhip:#{@hash_ip}\n#{@client_ip}"
    end
    if !p.nil? and @hash_ip==ip
      p.register_dng_login(opac_secret,@client_ip)
    end
    # @msg="#{user} - #{opac_secret} - #{ip}"

    render :text=>@msg, :content_type=>'text/plain'
  end

  def wrong_contacts
  end

  def show
    headers['Access-Control-Allow-Origin'] = "*"
    @patron=ClavisPatron.find(params[:id])
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

end
