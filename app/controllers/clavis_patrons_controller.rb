# coding: utf-8
class ClavisPatronsController < ApplicationController
  # layout 'talking_books'
  layout 'csir'

  load_and_authorize_resource only: [:wrong_contacts,:show,:mancato_ritiro,:loans_analysis, :duplicates, :nppnc]
  respond_to :html

  def index
    @current_library = current_user.clavis_default_library
    if !params[:barcode].blank?
      barcode=params[:barcode].strip
      if barcode.to_i>0
        p_id = barcode.to_i
        searchfield=nil
        @patron = ClavisPatron.find(barcode) if ClavisPatron.exists?(barcode)
      else
        p_id = barcode.upcase
        searchfield='barcode'
        @patron = ClavisPatron.find_by_barcode(p_id)
      end
    end
    if @patron.nil?
      u=ClavisPatron.mydiscovery_user(p_id,searchfield)
      @patron = ClavisPatron.insert_or_update_patron(u) if !u.nil?
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

    sql = %Q{SELECT * FROM clavis.patron WHERE lower(opac_username) = lower(#{ClavisPatron.connection.quote(user)})}
    patron = ClavisPatron.find_by_sql(sql).first
    if !patron.nil?
      patron.allinea_da_clavis
    else
      msg = "- #{user}"
      render :text=>msg, :content_type=>'text/plain'
      return
    end

    # Da sostituire poi con: DngSession.format_client_ip(request)
    @client_ip=[request.remote_ip, request.headers['REMOTE_ADDR']].uniq.join(', ')
    # @client_ip=DngSession.format_client_ip(request)
    @hash_ip=Digest::SHA1.hexdigest(@client_ip)

    p=nil
    sql = %Q{SELECT patron_id FROM clavis.patron WHERE lower(opac_username) = lower(#{ClavisPatron.connection.quote(user)})
              and opac_enable='1' and opac_secret = #{ClavisPatron.connection.quote(opac_secret)}}
    p = ClavisPatron.find_by_sql(sql).first
    dng_session=nil
    if !p.nil?
      dng_session=p.register_dng_login(@client_ip)
    end
    if dng_session.nil?
      msg = "login failed"
    else
      msg = "login ok - #{dng_session.id}"
    end
    render :text=>msg, :content_type=>'text/plain'
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
    @current_library = current_user.clavis_default_library

    @pagetitle="Richieste a magazzino - #{@current_library.to_label} - #{@patron.lastname}"
    @da_clavis = params[:da_clavis].blank? ? false : true
    respond_to do |format|
      format.html { render layout:'csir' }
      format.js { }
    end
  end

  def csir_insert
    @patron=ClavisPatron.find(params[:id])
    @current_library = current_user.clavis_default_library

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
      if item.home_library_id == @current_library.id
        # render text:"qui item #{item.id}" and return
        begin
          item.item_loan_status_update
        rescue
          flash[:notice]=" [Topografico]"
        end
        if item.richiedibile?
          ClosedStackItemRequest.create(patron_id:@patron.id,item_id:item.id,dng_session_id:0,request_time:Time.now,created_by:current_user.id)
          flash[:notice]="Inserita richiesta per esemplare #{item.id} #{item.to_label}#{flash[:notice]}"
        else
          txt = item.in_deposito_esterno? ? ' in deposito esterno' : "loan_status =  #{item.loan_status}"
          flash[:notice]=" Richiesta non inserita: #{txt}"
        end
      else
        flash[:notice]="Esemplare con id #{item.id} non inserito (biblioteca #{item.home_library_id} - sei collegato come biblioteca #{@current_library.id}"
      end
    end
    render layout:'csir'
  end

  def purchase_proposals_count
    headers['Access-Control-Allow-Origin'] = "*"
    
    opac_username=params[:opac_username]
    #@patron=ClavisPatron.find_by_opac_username(opac_username.downcase)
    @patron=ClavisPatron.find_by_sql("SELECT * FROM clavis.patron WHERE lower(opac_username) = lower(#{ClavisPatron.connection.quote(opac_username)})").first
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

  # nppnc : Notifiche Pronti al Prestito Non Confermate
  def nppnc
    @records = ClavisPatron.notifiche_pronti_al_prestito_non_confermate(current_user.clavis_libraries_ids,params)
  end

  def cf
    headers['Access-Control-Allow-Origin'] = "*"
    respond_to do |format|
      format.html { render text:"json_only"}
      format.json {
        begin
          p = ClavisPatron.find(params[:id])
          p.allinea_da_clavis
          cf=p.codice_fiscale
          status='ok'
          error_message=''
        rescue
          cf = ''
          status='error'
          error_message="#{$!}"
        end
        render json:{cf:cf,status:status,error_message:error_message}
      }
    end
  end

end
