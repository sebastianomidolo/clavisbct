class SpItemsController < ApplicationController

  def ricollocati_a_scaffale_aperto
    @sp_items=SpItem.ricollocati_a_scaffale_aperto
  end

  def show
    if params[:id]=='random'
      @sp_item=SpItem.find_by_sql('select * from sp.sp_items order by random() limit 1').first
      @refresh = true
    else
      if params[:id]=='last'
        @sp_item=SpItem.find_by_sql('select * from sp.sp_items where updated_at notnull order by updated_at desc limit 1').first
      else
        @sp_item=SpItem.find(params[:id])
      end
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

  def info
    # headers['Access-Control-Allow-Origin'] = "*"
    @target_div="clavisbct_response"
    @sp_item=SpItem.find_by_item_id(params[:id])
    if @sp_item.nil?
      @sp_item=SpItem.new(collciv:params[:collciv],sbn_bid:params[:sbn_bid])
      if !@sp_item.collciv.blank?
        @sp_item.collciv.gsub!(' ', '.')
      end
    end
    if !@sp_item.nil?
      @clavis_manifestation=@sp_item.clavis_manifestation
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

end
