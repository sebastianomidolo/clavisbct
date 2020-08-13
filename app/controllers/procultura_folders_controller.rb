class ProculturaFoldersController < ApplicationController
  # layout 'procultura'
  # layout 'navbar'
  layout 'procult/procult'
  before_filter :authenticate_user!, only: [:update]
  load_and_authorize_resource only: :update


  def index
    @pagetitle='Procultura femminile - catalogo delle schede digitalizzate'
    archive_id=params[:archive_id]
    # logger.warn("reqfrom: #{params[:reqfrom]}")
    if !archive_id.blank?
      @procultura_archive=ProculturaArchive.find(archive_id)
      @partial='lista'
    else
      @partial='indice'
    end
    if !params[:reqfrom].blank?
      render :partial=>@partial
    else
      render :template=>"procultura_folders/#{@partial}"
    end
  end

  def show
    @pf=ProculturaFolder.find(params[:id])
    @pagetitle="Procultura femminile - Catalogo delle schede digitalizzate - #{@pf.archive.name} - #{@pf.label}"
    if !params[:reqfrom].blank?
      render :layout=>nil
    else
      @procultura_cards=@pf.cards_paginate(params)
    end
  end

  def update
    @procultura_folder=ProculturaFolder.find(params[:id])
    respond_to do |format|
      if @procultura_folder.update_attributes(params[:procultura_folder])
        format.html { redirect_to(@procultura_folder, :notice => 'ProculturaFolder was successfully updated.') }
        format.json { respond_with_bip(@procultura_folder) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@procultura_folder) }
      end
    end
  end


end
