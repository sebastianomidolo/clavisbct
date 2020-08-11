class SerialSubscriptionsController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_list
  load_and_authorize_resource
  respond_to :html

  def index
    @serial_subscriptions=SerialSubscription.all
  end

  private
  def set_serial_list
    @serial_list=SerialList.find(params[:serial_list_id])
  end
end
