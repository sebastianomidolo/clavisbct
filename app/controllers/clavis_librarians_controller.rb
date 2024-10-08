
class ClavisLibrariansController < ApplicationController
  layout 'navbar'
  load_and_authorize_resource

  def index
    @clavis_librarians = ClavisLibrarian.tutti(params)
  end

  def show
    @clavis_librarian = ClavisLibrarian.find(params[:id])
  end

end
