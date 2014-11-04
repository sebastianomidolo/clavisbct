class ContainersController < ApplicationController
  # GET /containers
  # GET /containers.json
  def index
    if params[:label].blank?
      @containers = Container.all(:order=>"replace(label,'SC','')::integer")
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

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @container }
      format.xml { render xml: @container }
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
end
