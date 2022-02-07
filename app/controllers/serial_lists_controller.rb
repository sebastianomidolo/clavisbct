class SerialListsController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_list, only: [:show, :edit, :update, :destroy, :import, :clone, :delete_library]

  load_and_authorize_resource except: [:index]
  
  respond_to :html

  def index
    if current_user.nil?
      @pagetitle="Liste periodici"
      @serial_lists=SerialList.lista_public
      render template:'serial_lists/index_public'
    else
      user = (can? :manage, SerialList) ? nil : current_user
      @pagetitle="Liste periodici #{current_user.email}"
      @serial_lists=SerialList.lista(params, user)
    end
  end

  def import
    config = Rails.configuration.database_configuration
    @sourcedir = config[Rails.env]["periodici_import"]
    @sourcefile = params[:sourcefile]
    if request.put?
      errors=@serial_list.import_data(File.join(@sourcedir,@sourcefile))
      redirect_to serial_titles_path(serial_list_id:@serial_list.id)
    end
  end

  def delete_titles
    @serial_list.delete_titles
    respond_with(@serial_list)
  end

  def delete_library
    if request.delete?
      @serial_list.delete_libraries([params[:library_id]])
      redirect_to serial_libraries_path(serial_list_id:@serial_list.id)
    end
  end

  def add_library
  end

  def clone
    if request.put?
      serial_list_id=@serial_list.id
      @serial_list=SerialList.new(params[:serial_list])
      @serial_list.title += " - #{Time.now}"
      @serial_list.save!
      @serial_list.clone_from_list(serial_list_id)
      redirect_to serial_titles_path(serial_list_id:@serial_list.id)
    else
      @serial_list.note="Lista copiata da #{@serial_list.title} (id: #{@serial_list.id})"
      @serial_list.title="Nuova lista"
    end
  end

  def new
    @serial_list = SerialList.new
    respond_with(@serial_list)
  end

  def create
    @serial_list=SerialList.new(params[:serial_list])
    @serial_list.save
    respond_with(@serial_list)
  end

  def destroy
    @serial_list.destroy
    respond_with(@serial_list)
  end

  def edit
  end

  def show
  end

  def update
    @serial_list.update_attributes(params[:serial_list])
    # redirect_to controller:'serial_lists', action:'index'
    respond_with(@serial_list)
  end

  private
  def set_serial_list
    @serial_list = SerialList.find(params[:id])
  end

end
