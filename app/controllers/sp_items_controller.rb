class SpItemsController < ApplicationController
  def show
    @sp_item=SpItem.find(params[:id])
    @h1_title='Proposte bibliografiche'
    @h1_link="/sp_bibliographies"
    @h2_title=@sp_item.sp_section.sp_bibliography.title
    @css_id='bibliografie'
    render :layout=>params[:layout] if !params[:layout].blank?
  end
end
