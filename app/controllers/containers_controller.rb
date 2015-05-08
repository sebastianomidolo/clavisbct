class ContainersController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  # GET /containers
  # GET /containers.json
  def index
    if params[:label].blank?
      @containers = Container.lista
    else
      @container = Container.find_by_label(params[:label])
      render action: 'show' and return
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @containers }
    end
  end

  # GET /containers/1
  # GET /containers/1.json
  def show
    @container = Container.find(params[:id])
    user_session[:current_container]=@container.label
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @container }
      format.xml { render xml: @container }
    end
  end

  def update
    @container = Container.find(params[:id])
    respond_to do |format|
      if @container.update_attributes(params[:container])
        format.html { redirect_to @container, notice: 'Container item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @container.errors, status: :unprocessable_entity }
      end
    end
  end

  def barcodes
    respond_to do |format|
      format.csv {
        csv_data=Container.barcodes.collect {|x| x['barcode']}
        send_data csv_data.join("\n"), type: Mime::CSV, disposition: "attachment; filename=container_items.csv"
      }
    end
  end

  def new
    @container = Container.new
  end

  def create
    @container = Container.new(params[:container])
    @container.created_by=current_user
    @container.save
    respond_with(@container)
  end

  def destroy
    @container = Container.find(params[:id])
    @container.destroy
    respond_to do |format|
      format.html { redirect_to containers_url }
    end
  end
end
