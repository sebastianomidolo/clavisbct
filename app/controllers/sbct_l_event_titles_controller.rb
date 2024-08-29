# coding: utf-8

class SbctLEventTitlesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource except: [:create, :update, :destroy]
  
  respond_to :html

  def edit
    @sbct_l_event_title = SbctLEventTitle.find(params[:id])
    @sbct_l_event_title.validated_by = current_user.id
    @sbct_event = @sbct_l_event_title.sbct_event
    @sbct_title = @sbct_l_event_title.sbct_title
    @requester = User.find(@sbct_l_event_title.requested_by)
  end

  def create
    l = SbctLEventTitle.new(params[:sbct_l_event_title])
    l.requested_by = current_user.id
    l.request_date = Time.now
    l.save
    redirect_to sbct_title_path(l.sbct_title)
  end

  def update
    le = SbctLEventTitle.find(params[:id])
    if can? :update, le, current_user
      le.validating_now = params[:validating_now]
      if le.validating_now
        le.validated_by = current_user.id
      else
        le.updated_by = current_user.id
      end
      le.update_attributes(params[:sbct_l_event_title])
      if le.validating_now
        redirect_to sbct_event_path(le.sbct_event)
      else
        edit_ok = '1'
        redirect_to sbct_title_path(le.sbct_title,modifiche:edit_ok)
      end
    else
      render text:'non autorizzato', layout:true and return
    end
  end

  def destroy
    l = SbctLEventTitle.find(params[:id])
    l.destroy
    redirect_to sbct_title_path(l.sbct_title)
  end

  
end
