class ClavisItemsController < ApplicationController
  def show
    i=ClavisItem.find(params[:id])
    redirect_to i.clavis_url
  end
end

