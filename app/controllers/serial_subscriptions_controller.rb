class SerialSubscriptionsController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_list, only:[:index]
  load_and_authorize_resource
  respond_to :html

  def index
    @serial_subscriptions=SerialSubscription.all
  end

  def update
    @serial_subscription=SerialSubscription.find(params[:id])
    @serial_subscription.update_attributes(params[:serial_subscription])
    respond_to do |format|
      format.json { respond_with_bip(@serial_subscription) }
    end

  end

  private
  def set_serial_list
    @serial_list=SerialList.find(params[:serial_list_id])
  end
end
