class TalkingBooksController < ApplicationController
  # GET /talking_books
  # GET /talking_books.json
  def index
    @talking_books = TalkingBook.all

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

  # GET /talking_books/new
  # GET /talking_books/new.json
  def new
    @talking_book = TalkingBook.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @talking_book }
    end
  end

  # GET /talking_books/1/edit
  def edit
    @talking_book = TalkingBook.find(params[:id])
  end

  # POST /talking_books
  # POST /talking_books.json
  def create
    @talking_book = TalkingBook.new(params[:talking_book])

    respond_to do |format|
      if @talking_book.save
        format.html { redirect_to @talking_book, notice: 'Talking book was successfully created.' }
        format.json { render json: @talking_book, status: :created, location: @talking_book }
      else
        format.html { render action: "new" }
        format.json { render json: @talking_book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /talking_books/1
  # PUT /talking_books/1.json
  def update
    @talking_book = TalkingBook.find(params[:id])

    respond_to do |format|
      if @talking_book.update_attributes(params[:talking_book])
        format.html { redirect_to @talking_book, notice: 'Talking book was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @talking_book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /talking_books/1
  # DELETE /talking_books/1.json
  def destroy
    @talking_book = TalkingBook.find(params[:id])
    @talking_book.destroy

    respond_to do |format|
      format.html { redirect_to talking_books_url }
      format.json { head :no_content }
    end
  end
end
