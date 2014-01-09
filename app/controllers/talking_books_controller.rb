class TalkingBooksController < ApplicationController
  layout 'navbar'
  # GET /talking_books
  # GET /talking_books.json
  def index
    qs=params[:qs]
    cond=[]
    if !qs.blank?
      ts=TalkingBook.connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('simple', titolo) @@ to_tsquery('simple', '#{ts}')"
    end
    type=params[:digitalized]
    if type=='yes'
      logger.warn("type: solo digitalizzati")
      cond << "digitalizzato notnull"
    else
      logger.warn("type: tutti")
    end
    cond = cond.join(" AND ")

    @talking_books = TalkingBook.paginate(:conditions=>cond,:page=>params[:page], :include=>[:clavis_item])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @talking_books }
    end
  end

  # GET /talking_books/1
  # GET /talking_books/1.json
  def show
    @talking_book = TalkingBook.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @talking_book }
    end
  end

  def download_mp3
    ack=DngSession.access_control_key(params,request)
    if ack!=params[:ac]
      render :text=>'error', :content_type=>'text/plain'
      return
    end
    @talking_book = TalkingBook.find(params[:id])
    dng = DngSession.find_by_params_and_request(params,request)
    @clavis_patron=ClavisPatron.find_by_opac_username(params[:dng_user].downcase)
    if @clavis_patron.nil? or @clavis_patron.id!=dng.patron.id
      render :text=>'user error', :content_type=>'text/plain'
      return
    end

    # Utente @clavis_patron autorizzato al download nella sessione corrente
    cm=ClavisManifestation.find(params[:mid])
    zipfile=@talking_book.zip_filepath(@clavis_patron, cm)
    if !File.exist?(zipfile)
      @talking_book.make_audio_zip(@clavis_patron, cm)
    end
    send_file(zipfile)
  end
end
