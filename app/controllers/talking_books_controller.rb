class TalkingBooksController < ApplicationController
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

end
