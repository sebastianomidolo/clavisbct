class ClosedStackItemRequestsController < ApplicationController
  layout 'navbar'
  before_filter :set_dng_session, only: [:index, :check, :item_delete]

  load_and_authorize_resource only: [:index,:print,:confirm_request,:csir_delete, :csir_archive]

  def index
    patron_id = params[:patron_id]
    pending = params[:pending]=='1' ? true : false
    printed = params[:printed]=='1' ? true : false
    today = params[:all].blank? ? true : false
    if !patron_id.blank?
      @patron = ClavisPatron.find(patron_id)
      @csir = ClosedStackItemRequest.list(@patron.id,pending,printed,today)
    end
    respond_to do |format|
      format.html {}
      format.js {
        render template:'closed_stack_item_requests/index'
      }
    end
  end

  def confirm_request
    @clavis_patron=ClavisPatron.find(params[:patron_id])
    @daily_counter = ClosedStackItemRequest.assign_daily_counter(@clavis_patron)
    respond_to do |format|
      format.html { render text:'ok'}
      format.js { }
    end
  end

  def csir_delete
    headers['Access-Control-Allow-Origin'] = '*'
    @csir=ClosedStackItemRequest.find(params[:id])
    m=@csir.attributes
    @csir.destroy
    @clavis_patron=ClavisPatron.find(@csir.patron_id)
    respond_to do |format|
      format.html { render text:"richiesta cancellata: #{m}" }
      format.js
    end
  end

  def csir_archive
    headers['Access-Control-Allow-Origin'] = '*'
    @csir=ClosedStackItemRequest.find(params[:id])
    @clavis_patron=ClavisPatron.find(@csir.patron_id)
    @csir.archived=!(@csir.archived)
    @csir.save
    respond_to do |format|
      format.html { render text:"richiesta archiviata" }
      format.js
    end
  end

  # Utilizzata solo via interfaccia utente DiscoveryNG per utente non loggato,
  # ma autentcato tramite dng_session
  # Per utente loggato usare csir_delete
  def item_delete
    headers['Access-Control-Allow-Origin'] = "*"
    respond_to do |format|
      format.html {render :text=>'cancellazione solo via js'}
      format.js {
        @target_div=params[:target_div]
        ir=ClosedStackItemRequest.find(params[:id])
        logger.warn("destroy_closed_stack_item_request #{ir.id}")
        ir.destroy if !@dng_session.nil?
        # render template:'closed_stack_item_requests/deleted_ok'
        render template:'closed_stack_item_requests/check'
      }
    end
  end

  def insert_item_for_patron
    patron=ClavisPatron.find(params[:patron_id])
    serieinv=params[:serieinv].strip.upcase
    serie,inv=serieinv.split('-')
    if inv.blank?
      item_id=serie
      item = ClavisItem.exists?(item_id) ? ClavisItem.find(item_id) : nil
    else
      item=ClavisItem.find_by_inventory_serie_id_and_inventory_number(serie.upcase,inv)
    end
    render text:"Esemplare non trovato: #{serieinv}" and return if item.nil?
    ClosedStackItemRequest.create(patron_id:patron.id,item_id:item.id,dng_session_id:0,request_time:Time.now,created_by:current_user.id)
    redirect_to clavis_patron_path(patron)
  end

  def check
    respond_to do |format|
      format.html
      format.js {
        @target_div=params[:target_div]
      }
      format.pdf  {
        filename="#{@dng_session.id}.pdf"
        patron=ClavisPatron.find(@dng_session.patron_id)
        pdf=patron.closed_stack_item_request_pdf(@dng_session)
        send_data(pdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
    end
  end

  def print
    @patron_id = params[:patron_id].blank? ? nil : ClavisPatron.find(params[:patron_id]).id
    @reprint = params[:reprint]=='true' ? true : false
    # @records=ClosedStackItemRequest.richieste_magazzino(@patron_id,@reprint)
    @records=ClosedStackItemRequest.list(@patron_id,pending=false,printed=false,today=true,archived=false,reprint=@reprint)
    # @records=ClosedStackItemRequest.list(@patron_id,reprint=@reprint)
    respond_to do |format|
      format.html {
      }
      format.pdf {
        filename="elenco_richieste_a_magazzino.pdf"
        send_data(ClosedStackItemRequest.list_pdf(@records,@patron_id,@reprint),
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
        ClosedStackItemRequest.mark_as_printed(@records)
      }
    end
  end

  def random_insert
    ClosedStackItemRequest.random_insert
    redirect_to controller:'closed_stack_item_requests'
  end

  private
  def set_dng_session
    @dng_session=DngSession.find_by_params_and_request(params,request)
  end
  

end
