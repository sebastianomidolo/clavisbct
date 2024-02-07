# coding: utf-8

class SbctEventsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="PAC - Eventi"
    user_session[:events_mode]='on'
    user_session[:sbct_event] = nil
    status = params[:sbct_event_status]
    status = 'C' if status.blank?
    @sbct_events = SbctEvent.where("event_status_id = #{SbctEvent.connection.quote(status)}")
  end
  def create
    @sbct_event = SbctEvent.new(params[:sbct_event])
    @sbct_event.created_by = current_user.id
    @sbct_event.save
    redirect_to sbct_events_path
  end

  def update
    @sbct_event = SbctEvent.find(params[:id])
    if @sbct_event.update_attributes(params[:sbct_event])
      @sbct_event.updated_by=current_user.id
      @sbct_event.save
      flash[:notice] = "Modifiche salvate"
      respond_with @sbct_event
    else
      render :action => "edit"
    end
  end

  def show
    p={sbct_event:@sbct_event.id}
    sql=SbctTitle.sql_for_tutti(p,current_user).first
    @sbct_titles = SbctTitle.find_by_sql(sql)
    user_session[:sbct_titles_ids]=@sbct_titles.collect {|i| i.id}
    user_session[:sbct_titles_ids] = user_session[:sbct_titles_ids].uniq
    user_session[:sbct_event] = @sbct_event.id
  end

  def destroy
    @sbct_event.destroy if @sbct_event.sbct_titles.size==0
    redirect_to sbct_events_path
  end

end
