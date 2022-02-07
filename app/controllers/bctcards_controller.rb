class BctcardsController < ApplicationController
  # layout 'bctcards'
  layout 'bioico'
  # layout 'procult/procult'

  before_filter :set_card, only: [:show]

  respond_to :html

  def index
    @namespace=params[:namespace]
    if params[:lettera].blank?
      @show_searchbox = true
    else
      # @bio_iconografico_cards=BioIconograficoCard.search(params)
      # return
    end
    @bio_iconografico_cards=BioIconograficoCard.search(params)
    return

    if params[:topic_id].blank?
      @bio_iconografico_cards=BioIconograficoCard.search(params)
      # @bio_iconografico_cards=BioIconograficoCard.search_qs(params[:qs])
    else
      @bio_iconografico_cards=BioIconograficoCard.search_topic(params[:topic_id].to_i)
    end
  end

  def info
    params[:namespace] = BioIconograficoCard.default_namespace if params[:namespace].blank?
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

  private
    def set_card
      @bio_iconografico_card = BioIconograficoCard.find(params[:id])
      params[:lettera]=@bio_iconografico_card.lettera
    end

end
