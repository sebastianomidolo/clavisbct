# coding: utf-8

class SbctLEventTitlesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def create
    l = SbctLEventTitle.new(params[:sbct_l_event_title])
    l.save
    redirect_to sbct_title_path(l.sbct_title)
  end

  def update
    l = SbctLEventTitle.find(params[:id])
    if l.update_attributes(params[:sbct_l_event_title])
      l.save
    end
    redirect_to sbct_title_path(l.sbct_title)
  end

  def destroy
    l = SbctLEventTitle.find(params[:id])
    l.destroy
    redirect_to sbct_title_path(l.sbct_title)
  end

  
end
