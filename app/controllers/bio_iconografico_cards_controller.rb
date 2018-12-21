class BioIconograficoCardsController < ApplicationController
  layout 'bio_iconografico'
  before_filter :set_bio_iconografico_card, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:edit,:update,:upload,:numera,:index,:destroy]
  load_and_authorize_resource


  respond_to :html

  def index
    params[:namespace] = BioIconograficoCard.default_namespace(current_user) if params[:namespace].blank?
    if params[:lettera].blank?
      @show_searchbox = true
      if params[:bio_iconografico_card].blank?
        @bio_iconografico_card=BioIconograficoCard.new
        @bio_iconografico_card.tags={}.to_xml(root:'r',:skip_instruct => true, :indent => 0)
        @bio_iconografico_card.namespace=params[:namespace]
      else
        logger.warn "ok cards - lettera blank here: #{params['bio_iconografico_card']['intestazione']}"
        @bio_iconografico_card=BioIconograficoCard.new
        @bio_iconografico_card.tags={}.to_xml(root:'r',:skip_instruct => true, :indent => 0)
        @bio_iconografico_card.intestazione=params['bio_iconografico_card']['intestazione']
        @bio_iconografico_card.numero=params['bio_iconografico_card']['numero']
        @bio_iconografico_card.namespace=params['bio_iconografico_card']['namespace']
      end
      namespace=@bio_iconografico_card.namespace
    end
    params[:namespace]=namespace if params[:namespace].blank?
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

  def info
    params[:namespace] = BioIconograficoCard.default_namespace if params[:namespace].blank?
  end

  def numera
    @bio_iconografico_cards = BioIconograficoCard.senza_numero(params)
    render layout:'navbar'
  end

  def intesta
    @bio_iconografico_cards = BioIconograficoCard.senza_intestazione(params)
    render layout:'navbar'
  end


  def edit
    params[:namespace] = @bio_iconografico_card.namespace
  end

  def update
    # flash[:notice] = "Modifiche non salvate"
    respond_to do |format|
      if @bio_iconografico_card.update_attributes(params[:bio_iconografico_card])
        format.html {
          redirect_to controller: 'bio_iconografico_cards', action: 'index', lettera:@bio_iconografico_card.lettera, numero:@bio_iconografico_card.numero, namespace:@bio_iconografico_card.namespace
        }
        format.json { respond_with_bip(@bio_iconografico_card) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@bio_iconografico_card) }
      end
    end
  end

  def show
    @bio_iconografico_card=BioIconograficoCard.find(params[:id])
    params[:namespace] = @bio_iconografico_card.namespace
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

  def delete
    @bio_iconografico_card.destroy
    redirect_to bio_iconografico_cards_path(:lettera=>@bio_iconografico_card.lettera), notice: 'Cancellazione effettuata' 
  end

  private
    def set_bio_iconografico_card
      @bio_iconografico_card = BioIconograficoCard.find(params[:id])
      params[:lettera]=@bio_iconografico_card.lettera
    end

end
