# coding: utf-8

class SbctPresetsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource except: [:index]
  respond_to :html

  def index
    @sbct_presets = SbctPreset.order 'lower(label)'
  end

  def new
    @sbct_preset.path = params[:path]
  end

  def create
    @sbct_preset.created_by = current_user.id
    @sbct_preset.save
    respond_with(@sbct_preset)
  end

  def show
  end

  def update
    if @sbct_preset.update_attributes(params[:sbct_preset])
      @sbct_preset.save
      flash[:notice] = "Modifiche salvate"
      respond_with(@sbct_preset)
    else
      render :action => "edit"
    end
  end

  def destroy
    @sbct_preset.destroy
    redirect_to sbct_presets_path
  end

end
