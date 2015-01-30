
class OpenShelfItemsController < ApplicationController
  before_filter :set_open_shelf_item_id, only: [:insert, :delete]
  before_filter :authenticate_user!, only: [:insert, :delete]

  def insert
    o=OpenShelfItem.find_or_create_by_item_id(@open_shelf_item_id)
    o.created_by=current_user.id
    o.save
    respond_to do |format|
      format.html {render :text=>"item #{@open_shelf_item_id} aggiunto a scaffale aperto"}
      format.js
    end
  end
  def delete
    if OpenShelfItem.exists?(@open_shelf_item_id)
      OpenShelfItem.find(@open_shelf_item_id).destroy
    end
    respond_to do |format|
      format.html {render :text=>"item #{@open_shelf_item_id} cancellato da scaffale aperto"}
      format.js
    end
  end


  private
  def set_open_shelf_item_id
    @open_shelf_item_id = params[:id]
  end
  
end
