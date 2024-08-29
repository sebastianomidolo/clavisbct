# coding: utf-8
class BibSectionsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="Schema collocazioni - Ubicazioni"
    render text:'error', layout:true and return if params[:library_id].to_i < 1
    @clavis_library=ClavisLibrary.find(params[:library_id].to_i)
    @bib_sections=BibSection.where(library_id:@clavis_library.id).order(:name)
    ids = current_user.clavis_libraries.collect{|l| l.library_id}
    @managed_library = true if ids.include?(params[:library_id].to_i)
  end

  def edit
  end
  def show
    @clavis_library = @bib_section.clavis_library
    @locations = Location.list({conditions:["bib_section_id=#{@bib_section.id}"]})
  end
  def new
    ids = current_user.clavis_libraries.collect{|l| l.library_id}
    render text:"biblioteche su cui sei autorizzato a inserire ubicazioni #{ids}", layout:true and return if !ids.include?(params[:library_id].to_i)
    @bib_section = BibSection.new(library_id:params[:library_id])
    @clavis_library = @bib_section.clavis_library
  end
  def create
    @bib_section = BibSection.new(params[:bib_section])
    @bib_section.save
    redirect_to bib_sections_url(library_id:@bib_section.library_id)
  end

  def update
    if @bib_section.update_attributes(params[:bib_section])
      @bib_section.save
      flash[:notice] = "Modifiche salvate"
      respond_with(@bib_section)
    else
      render :action => "edit"
    end
  end

  def destroy
    library_id=@bib_section.library_id
    url=bib_sections_url(library_id:library_id)
    @bib_section.destroy
    redirect_to url
  end


end
