class SpItemsController < ApplicationController
  def show
    @sp_item=SpItem.find(params[:id])
  end

end
