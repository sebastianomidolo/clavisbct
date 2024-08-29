class StatsController < ApplicationController
  before_filter :set_stat, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @stats = Stat.all
    respond_with(@stats)
  end

  def show
    respond_with(@stat)
  end

  def new
    @stat = Stat.new
    respond_with(@stat)
  end

  def edit
  end

  def create
    @stat = Stat.new(params[:stat])
    @stat.save
    respond_with(@stat)
  end

  def update
    @stat.update_attributes(params[:stat])
    respond_with(@stat)
  end

  def destroy
    @stat.destroy
    respond_with(@stat)
  end

  private
    def set_stat
      @stat = Stat.find(params[:id])
    end
end
