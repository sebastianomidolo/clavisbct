class BctPlacesController < ApplicationController
  before_filter :set_bct_place, only: [:show, :edit, :update, :destroy]
  # before_filter :authenticate_user!, only: [:edit, :update, :destroy]
  before_filter :authenticate_user!
  before_filter :trova_fondo_corrente

  # layout 'lettereautografe'

  def show
    @bct_person=BctPerson.find(params[:bct_person_id]) if !params[:bct_person_id].nil?
  end


  private
    def set_bct_place
      @bct_place = BctPlace.find(params[:id])
    end
    def trova_fondo_corrente
      @fondo_corrente = params[:fondo_id].nil? ? nil : BctFondo.find(params[:fondo_id])
    end

end
