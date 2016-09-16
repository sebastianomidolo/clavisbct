class OmekaItemsController < ApplicationController

  def index
    @omeka_items=OmekaItem.where('public').order('id desc')
    @omeka_items=OmekaItem.where('true').order('id desc')
  end

  def show
    @omeka_item=OmekaItem.find(params[:id])
  end

end
