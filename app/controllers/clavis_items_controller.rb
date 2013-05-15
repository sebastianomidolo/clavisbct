class ClavisItemsController < ApplicationController
  def show
    @clavis_item=ClavisItem.find(params[:id])
    redirect_to @clavis_item.clavis_url if !params[:redir].blank?
  end
end

