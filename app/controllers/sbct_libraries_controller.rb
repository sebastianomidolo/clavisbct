class SbctLibrariesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="PAC - Biblioteche"
    @sbct_suppliers = SbctSupplier.tutti(params)
  end

end
