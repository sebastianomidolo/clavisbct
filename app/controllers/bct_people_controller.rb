class BctPeopleController < ApplicationController
  before_filter :set_bct_person, only: [:show, :edit, :update, :destroy]
  # before_filter :authenticate_user!, only: [:edit, :update, :destroy]
  before_filter :authenticate_user!
  before_filter :trova_fondo_corrente

  layout 'lettereautografe'

  respond_to :html

  def index
    @bct_person = BctPerson.new(params[:bct_person])
    @bct_person.denominazione='' if @bct_person.denominazione.nil?
    per_page=100
    cond=[]
    @searchterm=@bct_person.denominazione.downcase
    cond << "denominazione ~* '#{@searchterm}'" if !@searchterm.blank?
    cond << "fondo_id=#{@fondo_corrente.id}" if !@fondo_corrente.nil?
    @bct_people=BctPerson.lista_con_lettere(params[:page], cond.join(' AND '), per_page)
    @persists_form=params[:persists_form]
    @searchterm=@bct_person.denominazione.downcase
    respond_with(@bct_people)
  end

  def show
    respond_with(@bct_person)
  end

  def new
    @bct_person = BctPerson.new
    respond_with(@bct_person)
  end

  def edit
  end

  def create
    @bct_person = BctPerson.new(params[:bct_person])
    @bct_person.save
    respond_with(@bct_person)
  end

  def update
    @bct_person.update_attributes(params[:bct_person])
    respond_with(@bct_person)
  end

  #def destroy
  #  @bct_person.destroy
  #  respond_with(@bct_person)
  #end

  private
    def set_bct_person
      @bct_person = BctPerson.find(params[:id])
    end
    def trova_fondo_corrente
      @fondo_corrente = params[:fondo_id].nil? ? nil : BctFondo.find(params[:fondo_id])
    end
end
