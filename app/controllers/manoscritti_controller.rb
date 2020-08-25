class ManoscrittiController < ApplicationController
  layout 'manoscritti'

  before_filter :set_manoscritto, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:edit,:update,:destroy]
  load_and_authorize_resource only: [:edit,:update,:destroy]

  respond_to :html

  def index
    @manoscritti = Manoscritto.where('sortkey is not null').order('sortkey');
    respond_with(@manoscritti)
  end

  def show
    respond_with(@manoscritto)
  end

  def new
    @manoscritto = Manoscritto.new
    respond_with(@manoscritto)
  end

  def edit
  end

  def create
    @manoscritto = Manoscritto.new(params[:manoscritto])
    @manoscritto.save
    respond_with(@manoscritto)
  end

  def update
    @manoscritto.update_attributes(params[:manoscritto])
    respond_with(@manoscritto)
  end

  def destroy
    @manoscritto.destroy
    respond_with(@manoscritto)
  end

  private
    def set_manoscritto
      @manoscritto = Manoscritto.find(params[:id])
    end
end
