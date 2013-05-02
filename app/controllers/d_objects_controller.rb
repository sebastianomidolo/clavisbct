class DObjectsController < ApplicationController
  # GET /d_objects
  # GET /d_objects.json
  def index
    cond=[]
    cond << "mime_type='#{params[:mime_type]}'" if !params[:mime_type].blank?
    cond << "filename ~* #{ActiveRecord::Base.connection.quote(params[:filename])}" if !params[:filename].blank?
    cond = cond.join(" AND ")
    cond = "false" if cond.blank?
    order='filename'
    @d_objects = DObject.paginate(:conditions=>cond,
                                  :page=>params[:page],
                                  :order=>order)

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

end
