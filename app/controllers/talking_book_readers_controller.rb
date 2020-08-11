class TalkingBookReadersController < ApplicationController
  layout 'navbar'
  load_and_authorize_resource
  before_filter :set_talking_book_reader, only: [:show, :edit, :update, :destroy]
  respond_to :html

  def index
    sql=%Q{select v.id,v.nome,v.cognome,v.attivo,count(c.id)
                  from #{TalkingBookReader.table_name} v left join #{TalkingBook.table_name} c on (c.talking_book_reader_id=v.id)
                  group by v.id,v.nome,v.cognome,v.attivo order by lower(cognome),lower(nome)}
    @tbr = TalkingBookReader.find_by_sql(sql)
  end

  def show
    @talking_book_reader = TalkingBookReader.find(params[:id])
  end

  def edit
  end

  def new
    @talking_book_reader = TalkingBookReader.new
  end

  def create
    @talking_book_reader = TalkingBookReader.new(params[:talking_book_reader])
    @talking_book_reader.save
    respond_with(@talking_book_reader)
  end

  def update
    @talking_book_reader.update_attributes(params[:talking_book_reader])
    respond_with(@talking_book_reader)
  end
  
  private
  def set_talking_book_reader
    @talking_book_reader = TalkingBookReader.find(params[:id])
  end

end
