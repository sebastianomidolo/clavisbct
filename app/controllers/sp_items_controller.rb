# coding: utf-8
class SpItemsController < ApplicationController
  layout 'sp_bibliographies'
  before_filter :authenticate_user!, only: [:new,:create,:update,:destroy,:edit]
  before_filter :set_sp_item_id, only: [:new,:show,:edit,:update,:destroy]
  load_and_authorize_resource only: [:new,:create,:update,:destroy,:edit]
  respond_to :html

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

    if current_user.nil?
      render text:"Risorsa non disponibile", layout:'sp_bibliographies' and return if !@sp_item.published?
    end
    
    @h1_title='Proposte bibliografiche'
    @h1_link="/sp_bibliographies"
    if @sp_item.sp_section.nil?
      @h2_title=@sp_item.sp_bibliography.title
    else
      @h2_title=@sp_item.sp_section.sp_bibliography.title
    end
    @css_id='bibliografie'
    @pagetitle=@sp_item.sp_section.nil? ? @h2_title : @sp_item.sp_section.title

    @d_object = DObject.find(params[:d_object]) if !params[:d_object].blank?
    @page = params[:page]
    render :layout=>params[:layout] if !params[:layout].blank?
  end

  def redir
    @cm = ClavisManifestation.find(params[:manifestation_id])
    @sp_items = SpItem.find_all_by_manifestation_id(params[:manifestation_id])
    @sp_bibliography = SpBibliography.new
    # render text:@sp_items.size and return
    # sp_item_ids = cm.sp_item_ids_with_d_objects
    # NB: sp_item_ids è un array, gli ids potrebbero essere più di uno
    # al momento considero solo il primo
    #sp_item = sp_item_ids.first
    #render text:'resource not available' and return if sp_item.nil?
    #redirect_to sp_item_path(sp_item)
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

  def edit
  end

  def new
    @sp_item = SpItem.new
    if params[:section_id].blank?
      @sp_section = SpSection.new(parent:0)
      @sp_bibliography = SpBibliography.find(params[:bibliography_id])
    else
      @sp_section = SpSection.find(params[:section_id]) 
      @sp_bibliography = @sp_section.sp_bibliography
    end
    @sp_item.sp_bibliography = @sp_bibliography
    @sp_item.section_number = @sp_section.number
    respond_with(@sp_item)
  end

  def create
    @sp_item=SpItem.new(params[:sp_item])
    @sp_item.created_by=current_user.id
    @sp_item.save
    @sp_bibliography=@sp_item.sp_bibliography
    respond_with(@sp_item)
  end

  def update
    upd = params[:sp_item]
    upd['updated_by'] = current_user.id
    @sp_item.update_attributes(upd)
    respond_with(@sp_item)
  end

  def destroy
    @sp_item.destroy
    redirect_to sp_bibliography_path(@sp_bibliography)
  end

  private
  def set_sp_item_id
    if params[:id].blank?
      @sp_item=SpItem.new
      if params[:section_id].blank?
        @sp_bibliography=SpBibliography.find(params[:bibliography_id])
      else
        @sp_section=SpSection.find(params[:section_id])
        @sp_bibliography=@sp_section.sp_bibliography
        @sp_item.section_number=@sp_section.number
      end
      @sp_item.sp_bibliography=@sp_bibliography
    else
      @sp_item=SpItem.find(params[:id])
      @sp_bibliography=@sp_item.sp_bibliography
      @sp_section=@sp_item.sp_section
    end
  end

end
