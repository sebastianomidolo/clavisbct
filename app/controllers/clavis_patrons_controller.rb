# coding: utf-8
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
    @da_clavis = params[:da_clavis].blank? ? false : true
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  def csir_insert
    @patron=ClavisPatron.find(params[:id])

    serieinv=params[:serieinv].strip.upcase
    serie,inv=serieinv.split('-')
    if inv.blank?
      # Se il formato di immissione è "serie-inventario" cerco per serie e inventario,
      # altrimenti assumo ricerca per collocazione (in questo caso la variabile serie contiene la collocazione)
      sql = "select item_id from clavis.collocazioni where collocazione = #{ClavisItem.connection.quote(serie)}"
      r=ClavisItem.connection.execute(sql).to_a.first
      item = r.nil? ? nil : ClavisItem.find(r['item_id'])
    else
      item=ClavisItem.find_by_inventory_serie_id_and_inventory_number(serie.upcase,inv)
    end
    if item.nil?
      flash[:notice]="Esemplare non trovato: #{serieinv}"
    else
      # Eventuale esemplare ricollocato:
      new_item = ClavisItem.trova_item_ricollocato(item)
      item = new_item if !new_item.nil?
      if item.home_library_id == 2
        x=ClosedStackItemRequest.create(patron_id:@patron.id,item_id:item.id,dng_session_id:0,request_time:Time.now,created_by:current_user.id)
        flash[:notice]="Inserita richiesta per esemplare #{item.to_label}"
      else
        flash[:notice]="Esemplare con id #{item.id} non inserito perché è della biblioteca con id #{item.home_library_id}"
      end
    end
  end

  def purchase_proposals_count
    headers['Access-Control-Allow-Origin'] = "*"
    opac_username=params[:opac_username]
    @patron=ClavisPatron.find_by_opac_username(opac_username.downcase)
    render text:"not found" and return if @patron.nil?
    h = Hash.new
    h[:count] = @patron.purchase_proposals_count('1 year')
    h[:gender] = @patron.gender
    respond_to do |format|
      format.html { render text:"json_only"}
      format.json {
        render json:h.to_json
      }
    end
  end

end
