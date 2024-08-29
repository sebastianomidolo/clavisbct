# coding: utf-8
class LocationsController < ApplicationController
  layout 'sbct'

  before_filter :set_location, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource except: [:list]

  respond_to :html
  
  def index
    @pagetitle="Tabelle di Collocazione BCT"
    @clavis_library = ClavisLibrary.find(params[:library_id].to_i) if params[:library_id].to_i > 0
    #order = params[:order]=='p' ? 'loc_name,primo,secondo' : 'primo,loc_name,secondo'
    #order = 'id desc' if params[:order]=='id'
    #order = 'secondo' if params[:order]=='2e'
    cond = []
    cond << "bib_section_id=#{params[:bib_section_id]}" if !params[:bib_section_id].blank?
    cond << "library_id=#{params[:library_id].to_i}" if params[:library_id].to_i > 0
    # Nota: nessun problema qui passando direttamente params[:order] in quanto il parametro viene filtrato dalla Location.list evitando sql injections
    @collocazioni=Location.list({order:params[:order],conditions:cond})
    if !params[:library_id].blank?
      ids = current_user.clavis_libraries.collect{|l| l.library_id}
      @managed_library=true if ids.include?(params[:library_id].to_i)
    end
  end

  def show
  end

  def edit
  end

  def create
    @location = Location.new(params[:location])
    if @location.bib_section_id==0
    # render text:'ok procedo con creazione location scegliendo bib_section' and return
      redirect_to new_location_path(library_id:@location.library_id)
      return
    else
      @location.save
      respond_with(@location)
    end
  end

  def new
    @location = Location.new
    if params[:library_id].to_i > 0
      @location.library_id=params[:library_id].to_i
      @clavis_library = ClavisLibrary.find(@location.library_id)
      if @clavis_library.bib_sections.size == 0
        BibSection.create(library_id:@clavis_library.id,name:'Sezione principale')
      end
    end
  end

  def update
    @location.update_attributes(params[:location])
    respond_with(@location)
  end

  def destroy
    @location.destroy
    respond_with(@location)
  end

  private
  def set_location
    @location=Location.find(params[:id])
    @clavis_library = @location.bib_section.clavis_library
    @location.library_id = @clavis_library.id
    ids = current_user.clavis_libraries.collect{|l| l.library_id}
    @managed_library=true if ids.include?(@location.library_id)
  end
end
