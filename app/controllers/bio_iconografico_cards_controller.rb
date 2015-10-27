class BioIconograficoCardsController < ApplicationController
  layout 'bio_iconografico'
  before_filter :set_bio_iconografico_card, only: [:show, :edit, :update]
  before_filter :authenticate_user!, only: [:edit,:update,:upload]

  respond_to :html

  def index
    if params[:lettera].blank?
      @show_searchbox = true
      if params[:bio_iconografico_card].blank?
        @bio_iconografico_card=BioIconograficoCard.new
        @bio_iconografico_card.tags={}.to_xml(root:'r',:skip_instruct => true, :indent => 0)
      else
        @bio_iconografico_card=BioIconograficoCard.new(params[:bio_iconografico_card])
      end
    end
    @bio_iconografico_cards=BioIconograficoCard.list(params,@bio_iconografico_card)
  end

  def upload
    if request.method=="POST"
      uploaded_io = params[:filename]
      if uploaded_io.nil?
        render :template=>'bio_iconografico_cards/file_non_specificato'
      else
        @bio_iconografico_card=BioIconograficoCard.new.save_new_record(params,current_user)
        render :action=>:edit
      end
    else
      @bio_iconografico_card = BioIconograficoCard.new
    end
  end

  def edit
  end

  def update
    flash[:notice] = "Modifiche non salvate"
    @bio_iconografico_card.update_attributes(params[:bio_iconografico_card])
    # @bio_iconografico_card.save
    # respond_with(@bio_iconografico_card)

    params[:numero]=@bio_iconografico_card.numero
    @bio_iconografico_cards=BioIconograficoCard.list(params)
    render :action=>'index'
  end

  def show
    @bio_iconografico_card=BioIconograficoCard.find(params[:id])
    respond_to do |format|
      format.html {
        # render :layout=>nil
      }
      format.jpeg {
        fn=@bio_iconografico_card.filename_with_path
        img=Magick::Image.read(fn).first
        if !params[:size].blank?
          s=params[:size].split('x')
          # img.resize!(s[0].to_i,s[1].to_i)
          img.resize_to_fit!(s[0].to_i)
        end
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
      }
    end
  end


  private
    def set_bio_iconografico_card
      @bio_iconografico_card = BioIconograficoCard.find(params[:id])
      params[:lettera]=@bio_iconografico_card.lettera
    end

end
