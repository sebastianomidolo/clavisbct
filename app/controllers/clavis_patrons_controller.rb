# coding: utf-8
class ClavisPatronsController < ApplicationController
  # layout 'talking_books'

  load_and_authorize_resource only: [:wrong_contacts,:show,:mancato_ritiro,:loans_analysisx]
  respond_to :html

  def index
    if !params[:barcode].blank?
      barcode=params[:barcode].strip
      if barcode.to_i>0
        @patron = ClavisPatron.find(barcode) if ClavisPatron.exists?(barcode)
      else
        @patron = ClavisPatron.find_by_barcode(barcode.upcase)
      end
    end
    if @patron.nil?
      redirect_to:'closed_stack_item_requests'
    else
      render :action=>'show', layout:'csir'
    end
  end

  def duplicates
    @pagetitle = "Utenti Clavis duplicati"
    if params[:patron_ids].blank?
      @clavis_patrons = ClavisPatron.find_duplicates(params)
    else
      res = []
      params[:patron_ids].split(',').each do |id|
        begin
          res << "Verifico in tempo reale esistenza di utente #{id} - #{ClavisPatron.find(id).cancellami_se_non_esisto_in_clavis}"
        rescue
        end
      end
      @clavis_patrons = ClavisPatron.find_duplicates(params)
    end
    render layout:'csir'
  end

  def user_checkin_notification
    user=params[:user]
    opac_secret=params[:pass]
    ip=params[:ip]
    pwd=params[:p]

    # Da sostituire poi con: DngSession.format_client_ip(request)
    @client_ip=[request.remote_ip, request.headers['REMOTE_ADDR']].uniq.join(', ')
    # @client_ip=DngSession.format_client_ip(request)
    @hash_ip=Digest::SHA1.hexdigest(@client_ip)

    soap_auth=false
    p=nil
    if ClavisPatron.mydiscovery_authorized?(user,pwd)
      p=ClavisPatron.find_by_opac_username(user.downcase)
      soap_auth=true
    end
    if p.nil? and soap_auth==false
      @msg="NOTFOUND #{user} - secret: #{opac_secret}"
      @msg += " | soap_auth: #{soap_auth} --> pwd '#{pwd}' username = '#{user}'"
    else
      @msg="TROVATO #{p.opac_username} #{p.lastname} (soap_auth: #{soap_auth}) | #{@client_ip}"
    end
    dng_session=nil
    if !p.nil?
      dng_session=p.register_dng_login(@client_ip)
    end
    if dng_session.nil?
      fd=File.open("/home/seb/utenti_con_login_fallito.log", 'a')
      fd.write("#{Time.now} #{@msg}\n")
      fd.close
    else
      fd=File.open("/home/seb/utenti_con_login_ok.log", 'a')
      session_id = dng_session.nil? ? -1 : dng_session.id
      fd.write("#{Time.now} #{@msg} [dng_session: #{session_id}]\n")
      fd.close
    end
    
    # logger.warn("user_checkin_notification: #{@msg} [dng_session: #{dng_session}]")

    render :text=>@msg, :content_type=>'text/plain'
  end

  def wrong_contacts
  end

  def mancato_ritiro
  end

  def stat
  end

  def loans_analysis
    @clavis_patron=ClavisPatron.find(params[:id])
  end

  def autocert
    @clavis_patron=ClavisPatron.find(params[:id])
    respond_to do |format|
      format.html {
        render text:'test'
      }
      format.pdf {
        parametri = params
        @clavis_patron.define_singleton_method(:params) do
          parametri
        end
        lp=LatexPrint::PDF.new('autocert_spostamenti', @clavis_patron)
        send_data(lp.makepdf,
                  :filename=>'autocertificazione_spostamenti.pdf',:disposition=>'inline', :type=>'application/pdf')
      }
    end
  end

  def show
    headers['Access-Control-Allow-Origin'] = "*"
    @patron=ClavisPatron.find(params[:id])
    @pagetitle="Richieste a magazzino #{@patron.lastname}"
    @da_clavis = params[:da_clavis].blank? ? false : true
    respond_to do |format|
      format.html { render layout:'csir' }
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
        # render text:"qui item #{item.id}" and return
        item.item_loan_status_update
        x=ClosedStackItemRequest.create(patron_id:@patron.id,item_id:item.id,dng_session_id:0,request_time:Time.now,created_by:current_user.id)
        flash[:notice]="Inserita richiesta per esemplare #{item.to_label}"
      else
        flash[:notice]="Esemplare con id #{item.id} non inserito perché è della biblioteca con id #{item.home_library_id}"
      end
    end
    render layout:'csir'
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
