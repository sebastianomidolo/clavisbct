class SerialLibrariesController < ApplicationController
  layout 'periodici'
  load_and_authorize_resource
  respond_to :html

  def index
    id=params[:serial_list_id]
    @serial_list=SerialList.find(id)
    @serial_libraries=SerialLibrary.lista(id)
  end
  def add_libraries
  end
end
