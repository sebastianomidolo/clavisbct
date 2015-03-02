
class OpenShelfItemsController < ApplicationController
  before_filter :set_open_shelf_item, only: [:insert, :delete]
  before_filter :authenticate_user!, only: [:insert, :delete]

  def index
    @os_section=params[:os_section]
    @records=OpenShelfItem.dewey_list(@os_section)
  end

  def insert
    o=OpenShelfItem.find_or_create_by_item_id(@open_shelf_item_id)
    o.created_by=current_user.id
    o.os_section=@dest_section
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
  def set_open_shelf_item
    @clavis_item = ClavisItem.find(params[:id])
    @open_shelf_item_id = @clavis_item.id
    @dest_section=params[:dest_section]
  end
  
end
