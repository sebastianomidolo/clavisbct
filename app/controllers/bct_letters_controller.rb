class BctLettersController < ApplicationController
  before_filter :set_bct_letter, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:edit, :update, :destroy]
  # before_filter :authenticate_user!
  before_filter :trova_fondo_corrente


  layout 'lettereautografe'

  respond_to :html

  def index_no
    cond={}
    cond[:collocazione]=params[:collocazione] if !params[:collocazione].blank?
    @bct_letters = BctLetter.paginate(:conditions=>cond,:per_page=>300,:page=>params[:page])
    respond_with(@bct_letters)
  end


  def index
    conditions=[]

    if params[:person_id].blank?
      [:fondo_id,:mittente_id,:destinatario_id].each do |p|
        conditions << "#{p.to_s}=#{params[p]}" if !params[p].nil?
      end
      if !params[:argomento].nil?
        conditions << "argomento like '%#{params[:argomento]}%'"
      end
      if !params[:con_data].nil?
        conditions << 'data notnull'
      end
      conditions=conditions.join(' and ')
    else
      conditions="#{params[:person_id].to_i} IN (mittente_id,destinatario_id)"
    end
    if user_signed_in?
      order= 'letters.id'
    else
      order= conditions.size==0 ? nil : 'letters.data, people.denominazione'
    end
    @bct_letters=BctLetter.paginate :page => params[:page], :per_page => 10,
    :include=>[:bct_fondo,:placeto,:placefrom,:mittente,:destinatario], :conditions=>conditions,
    :conditions=>conditions,
    :order=>order
    respond_with(@bct_letters)
  end




  def show
    respond_with(@bct_letter)
  end

  def new
    @bct_letter = BctLetter.new
    respond_with(@bct_letter)
  end

  def edit
  end

  def create
    @bct_letter = BctLetter.new(params[:bct_letter])
    @bct_letter.save
    respond_with(@bct_letter)
  end

  def update
    respond_to do |format|
      params[:bct_letter][:updated_by]=current_user
      params[:bct_letter][:updated_at]=Time.now
      if @bct_letter.update_attributes(params[:bct_letter])
        format.html { respond_with(@bct_letter) }
        format.json { respond_with_bip(@bct_letter) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@bct_letter) }
      end
    end
  end

  #def destroy
  #  @bct_letter.destroy
  #  respond_with(@bct_letter)
  #end

  def random_letter
    # @bct_letter=BctLetter.random_letter_with_abstract
    @bct_letter=BctLetter.random_letter_with_pdf
  end

  private
    def set_bct_letter
      @bct_letter = BctLetter.find(params[:id])
    end
    def trova_fondo_corrente
      @fondo_corrente = params[:fondo_id].nil? ? nil : BctFondo.find(params[:fondo_id])
    end
end
