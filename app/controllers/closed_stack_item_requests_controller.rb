class ClosedStackItemRequestsController < ApplicationController
  layout 'navbar'
  before_filter :set_dng_session, only: [:index, :check]

  load_and_authorize_resource only: [:index]

  def index

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

  private
  def set_dng_session
    @dng_session=DngSession.find_by_params_and_request(params,request)
  end
  

end
