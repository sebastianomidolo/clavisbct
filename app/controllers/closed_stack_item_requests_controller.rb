class ClosedStackItemRequestsController < ApplicationController
  layout 'navbar'
  before_filter :set_dng_session, only: [:index, :check, :item_delete]

  load_and_authorize_resource only: [:index]

  def index
    patron_id = params[:patron_id]
    pending = params[:pending]=='1' ? true : false
    printed = params[:printed]=='1' ? true : false
    today = params[:all].blank? ? true : false
    if patron_id.blank?
      @patrons = ClosedStackItemRequest.patrons(today:today)
    else
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
    headers['Access-Control-Allow-Origin'] = "*"
    @clavis_patron=ClavisPatron.find(params[:id])
    @daily_counter = ClosedStackItemRequest.assign_daily_counter(@clavis_patron)
    respond_to do |format|
      format.html { render text:'ok'}
      format.js { }
    end

  end

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
    @records=ClosedStackItemRequest.richieste_magazzino
    respond_to do |format|
      format.html {
      }
      format.pdf {
        filename="elenco.pdf"
        send_data(ClosedStackItemRequest.list_pdf(@records),
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
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
