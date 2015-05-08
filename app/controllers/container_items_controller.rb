class ContainerItemsController < ApplicationController
  before_filter :authenticate_user!, only: [:edit, :update, :new, :destroy]

  # GET /container_items
  # GET /container_items.json
  def index
    if params[:label].blank?
      @container_items = ContainerItem.all(:order=>"replace(label,'SC','')::integer, row_number")
    else
      @containers_items = ContainerItem.where(:label=>params[:label]).order('row_number')
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @container_items }
    end
  end

  # GET /container_items/1
  # GET /container_items/1.json
  def show
    @container_item = ContainerItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @container_item }
    end
  end

  # GET /container_items/new
  # GET /container_items/new.json
  def new
    @container_item = ContainerItem.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @container_item }
    end
  end

  # GET /container_items/1/edit
  def edit
    @container_item = ContainerItem.find(params[:id])
  end

  # POST /container_items
  # POST /container_items.json
  def create
    @container_item = ContainerItem.new(params[:container_item])

    respond_to do |format|
      if @container_item.save
        format.html { redirect_to @container_item, notice: 'Container item was successfully created.' }
        format.json { render json: @container_item, status: :created, location: @container_item }
      else
        format.html { render action: "new" }
        format.json { render json: @container_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /container_items/1
  # PUT /container_items/1.json
  def update
    @container_item = ContainerItem.find(params[:id])

    respond_to do |format|
      if @container_item.update_attributes(params[:container_item])
        format.html { redirect_to @container_item, notice: 'Container item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @container_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /container_items/1
  # DELETE /container_items/1.json
  def destroy
    @container_item = ContainerItem.find(params[:id])
    @container=@container_item.container
    @container_item.destroy

    respond_to do |format|
      format.html { redirect_to container_items_url }
      format.json { head :no_content }
      format.js
    end
  end
end
