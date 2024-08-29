class DngSessionsController < ApplicationController
  layout 'navbar'
  before_filter :authenticate_user!
  load_and_authorize_resource
  
  def index
    @pagetitle='Sessioni dng'
    @patron = ClavisPatron.find(params[:patron_id]) if !params[:patron_id].blank?
    @sessions = DngSession.logfile(params,@patron)
  end

end
