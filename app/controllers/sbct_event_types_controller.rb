# coding: utf-8

class SbctEventTypesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="PAC - Tipologie eventi"
    @sbct_event_types = SbctEventType.all
  end

  def update
    @sbct_event_type = SbctEventType.find(params[:id])
    if @sbct_event_type.update_attributes(params[:sbct_event_type])
      @sbct_event_type.save
      flash[:notice] = "Modifiche salvate"
      redirect_to sbct_event_types_path
    else
      render :action => "edit"
    end
  end

  def create
    @sbct_event_type = SbctEventType.new(params[:sbct_event_type])
    @sbct_event_type.save
    redirect_to sbct_event_types_path
  end

end
