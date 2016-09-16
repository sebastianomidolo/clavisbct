class OmekaCollectionsController < ApplicationController

  def index
    @omeka_collections=OmekaCollection.collections_list
  end

  def show
    @omeka_collection=OmekaCollection.find(params[:id])
  end

end
