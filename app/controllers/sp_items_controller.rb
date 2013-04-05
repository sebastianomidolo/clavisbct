class SpItemsController < ApplicationController
  def show
    if params[:id]=='random'
      @sp_item=SpItem.find_by_sql('select * from sp.sp_items order by random() limit 1').first
      @refresh = true
    else
      @sp_item=SpItem.find(params[:id])
    end
    @h1_title='Proposte bibliografiche'
    @h1_link="/sp_bibliographies"
    if @sp_item.sp_section.nil?
      @h2_title=@sp_item.sp_bibliography.title
    else
      @h2_title=@sp_item.sp_section.sp_bibliography.title
    end
    @css_id='bibliografie'
    render :layout=>params[:layout] if !params[:layout].blank?
  end
end
