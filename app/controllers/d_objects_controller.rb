class DObjectsController < ApplicationController
  # GET /d_objects
  # GET /d_objects.json
  def index
    @d_objects = DObject.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @d_objects }
    end
  end

  # GET /d_objects/1
  # GET /d_objects/1.json
  def show
    @d_object = DObject.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @d_object }
    end
  end

  # GET /d_objects/new
  # GET /d_objects/new.json
  def new
    @d_object = DObject.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @d_object }
    end
  end

  # GET /d_objects/1/edit
  def edit
    @d_object = DObject.find(params[:id])
  end

  # POST /d_objects
  # POST /d_objects.json
  def create
    @d_object = DObject.new(params[:d_object])

    respond_to do |format|
      if @d_object.save
        format.html { redirect_to @d_object, notice: 'D object was successfully created.' }
        format.json { render json: @d_object, status: :created, location: @d_object }
      else
        format.html { render action: "new" }
        format.json { render json: @d_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /d_objects/1
  # PUT /d_objects/1.json
  def update
    @d_object = DObject.find(params[:id])

    respond_to do |format|
      if @d_object.update_attributes(params[:d_object])
        format.html { redirect_to @d_object, notice: 'D object was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @d_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /d_objects/1
  # DELETE /d_objects/1.json
  def destroy
    @d_object = DObject.find(params[:id])
    @d_object.destroy

    respond_to do |format|
      format.html { redirect_to d_objects_url }
      format.json { head :no_content }
    end
  end
end
