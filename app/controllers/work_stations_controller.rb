class WorkStationsController < ApplicationController
  before_filter :set_work_station, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    if params[:clavis_library_id].blank?
      @work_stations = WorkStation.where('true').order('clavis_library_id,id')
    else
      @work_stations = WorkStation.where(clavis_library_id:params[:clavis_library_id]).order('id')
    end
    respond_with(@work_stations)
  end

  def show
    respond_with(@work_station)
  end

  def new
    @work_station = WorkStation.new
    @work_station.processor='64'
    respond_with(@work_station)
  end

  def edit
  end

  def create
    @work_station = WorkStation.new(params[:work_station])
    @work_station.save
    respond_with(@work_station)
  end

  def update
    @work_station.update_attributes(params[:work_station])
    respond_with(@work_station)
  end

  def destroy
    @work_station.destroy
    respond_with(@work_station)
  end

  private
    def set_work_station
      @work_station = WorkStation.find(params[:id])
    end
end
