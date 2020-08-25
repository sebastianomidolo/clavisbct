

class IdentityCardsController < ApplicationController
  before_filter :authenticate_user!, except: [:new, :create, :newuser_show]
  load_and_authorize_resource except: [:new, :create, :newuser_show]

  layout 'navbar'
  respond_to :html

  def index
    @identity_cards = IdentityCard.where(:doc_uploaded=>true).order(:lastname,:name)
  end

  def new
    @identity_card = IdentityCard.new
  end

  def create
    # params[:identity_card].delete('email_confirmation')
    @identity_card = IdentityCard.new(params[:identity_card])
    @identity_card.unique_id = Digest::MD5.hexdigest(Time.now.to_s)

    if request.method=="POST"
      uploaded_io = params[:filename]
      if !uploaded_io.nil?
        full_filename=File.join(IdentityCard.file_storage, @identity_card.unique_id)
        File.open(full_filename, 'wb') do |file|
          file.write(uploaded_io.read)
        end
        @identity_card.doc_uploaded=true
      end
      @identity_card.client_ip=DngSession.format_client_ip(request)
    end
    @identity_card.save

    if !current_user.nil?
      respond_with(@identity_card)
    else
      render :action=>'newuser_show', :layout=>true
    end
  end

  def show
    @identity_card=IdentityCard.find(params[:id])
  end

  def docview
    @identity_card=IdentityCard.find(params[:id])
    if @identity_card.is_image? or @identity_card.is_pdf?
      img=Magick::Image.read(@identity_card.doc_filepath).first
      img.format='jpeg' if @identity_card.is_pdf?
      if !params[:size].blank?
        s=params[:size].split('x')
        if s[1].blank?
          img.resize_to_fit!(s[0].to_i)
        else
          img.resize_to_fit!(s[0].to_i,s[1].to_i)
        end
      end
      send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
    end
  end

  def newuser_show
    @identity_card=IdentityCard.find_by_unique_id(params[:unique_id])
  end

  def newuser_docview
    @identity_card=IdentityCard.find_by_unique_id(params[:unique_id])
  end

end
