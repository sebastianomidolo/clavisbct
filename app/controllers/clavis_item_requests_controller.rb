class ClavisItemRequestsController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  layout 'navbar'
  def index
    @request_date = params[:request_date]
    @clavis_item_requests=ClavisItemRequest.indice(params)
  end

end
