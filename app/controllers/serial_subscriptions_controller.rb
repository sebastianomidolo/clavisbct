class SerialSubscriptionsController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_list, only:[:index]
  before_filter :set_serial_subscription, only:[:edit,:show]
  load_and_authorize_resource
  respond_to :html

  def index
    @serial_subscriptions=SerialSubscription.all
  end

  def update
    @serial_subscription=SerialSubscription.find(params[:id])
    @serial_subscription.update_attributes(params[:serial_subscription])
    respond_to do |format|
      format.html { respond_with(@serial_subscription, :location=>serial_title_path(params.slice(:serial_list_id,:library_id,:estero,:tipo_fornitura,:sospeso))) }
      format.json { respond_with_bip(@serial_subscription) }
    end
  end

  def show
    @serial_list = @serial_subscription.serial_title.serial_list
  end

  def edit
  end

  private
  def set_serial_list
    @serial_list=SerialList.find(params[:serial_list_id])
  end
  def set_serial_subscription
    if SerialSubscription.exists?(params[:id]) and params[:ok_library_id].blank?
      @serial_subscription = SerialSubscription.find(params[:id])
    else
      cl = ClavisLibrary.find(params[:ok_library_id])
      pkey = [params[:id],cl.id]
      if SerialSubscription.exists?(pkey)
        @serial_subscription = SerialSubscription.find(pkey)
      else
        @serial_subscription = SerialSubscription.new(serial_title_id:params[:id],library_id:cl.id,numero_copie:0)
      end
    end
    @serial_title = @serial_subscription.serial_title
    @serial_list = @serial_title.serial_list
  end
end
