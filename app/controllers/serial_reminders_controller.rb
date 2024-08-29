# coding: utf-8

class SerialRemindersController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_list, only:[:index,:new,:reminders_send]
  before_filter :set_serial_reminder, only:[:show,:edit,:update,:destroy]

  load_and_authorize_resource except:[:index]
  respond_to :html

  def index
    if !@serial_list.nil?
      params[:filter]='D' if params[:filter].blank?
    else
      # params[:filter]=nil if params[:filter].blank?
    end
    @serial_reminders = SerialReminder.tutti(@serial_list,current_user,params)
    if @serial_title.nil?
    else
      @clavis_library = ClavisLibrary.find(params[:library_id])
      render template:'serial_reminders/index_for_title'
    end
  end

  def new
    @clavis_library = ClavisLibrary.find(params[:library_id])
    @serial_reminder.serial_title_id=@serial_title.id 
  end

  def show
  end

  def edit
    if params[:unset_reminder_date]=="true"
      # raise "res : #{params[:unset_reminder_date].class}"
      @serial_reminder.reminder_date = nil
      @serial_reminder.save
      redirect_to @serial_reminder
    end
  end

  def create
    @serial_reminder = SerialReminder.new(params[:serial_reminder])
    @serial_reminder.created_by = current_user.id
    @serial_reminder.save
    respond_with(@serial_reminder)
  end

  def destroy
    @serial_reminder.destroy
    redirect_to serial_reminders_path(serial_list_id:@serial_list.id)
  end

  # Contrassegna con la data corrente i solleciti ancora non inviati
  def reminders_send
    sql=SerialReminder.reminders_send(@serial_list,current_user)
    redirect_to serial_reminders_path(serial_list_id:@serial_list.id)
  end

  def update
    @serial_reminder.update_attributes(params[:serial_reminder])
    respond_with(@serial_reminder)
  end
  
  private
  def set_serial_list
    if params[:serial_title_id].nil?
      @serial_list=SerialList.find(params[:serial_list_id]) if !params[:serial_list_id].blank?
    else
      @serial_title = SerialTitle.find(params[:serial_title_id])
      @serial_list=@serial_title.serial_list
    end
  end
  def set_serial_reminder
    @serial_reminder = SerialReminder.find(params[:id])
    @serial_title = @serial_reminder.serial_title
    @serial_list=@serial_title.serial_list
  end
end

