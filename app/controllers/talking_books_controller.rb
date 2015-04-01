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
      # cond << "digitalizzato notnull"
      cond << "first_mp3_filename notnull"
    end
    type=params[:cdmp3]
    if type=='yes'
      cond << "cd notnull and digitalizzato notnull and da_inserire_in_informix='0'"
    end


    case params[:type]
    when 'novita'
      # cond << "data_collocazione notnull"
      mesi = params[:mesi].blank? ? 12 : params[:mesi].to_i
      mesi = 12 if mesi==0
      cond << "data_collocazione > now() - interval '#{mesi} months'"
    else
    end

    respond_to do |format|
      format.html {
        cond = cond.join(" AND ")
        if params[:htmloutput]=='yes'
          @talking_books = TalkingBook.find(:all,:conditions=>cond, :order=>'chiave,ordine')
          render :partial=>'talking_books/html_catalog'
          return
        else
          # @talking_books = TalkingBook.paginate(:conditions=>cond,:page=>params[:page], :include=>[:clavis_item])
          @talking_books = TalkingBook.paginate(:conditions=>cond,:page=>params[:page])
        end
      }
      format.csv {
        require 'csv'
        cond = cond.join(" AND ")
        @records = TalkingBook.find(:all,:conditions=>cond, :order=>'chiave,ordine')
        csv_string = CSV.generate do |csv|
          @records.each do |r|
            barcode = r.clavis_item.nil? ? "da controllare" : r.clavis_item.barcode
            csv << [barcode,r.n,r.digitalizzato]
          end
        end
        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=libriparlati_scaricabili.csv"
      }

      format.pdf {
        cond = cond.join(" AND ")
        @talking_books = TalkingBook.find(:all,:conditions=>cond, :order=>'chiave,ordine')
        pdf=TalkingBook.pdf_catalog(@talking_books)
        send_data(pdf, :disposition=>'inline', :type=>'application/pdf')
      }
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

  def digitalizzati
    respond_to do |format|
      format.pdf {
        TalkingBook.digitalizzati
        pdf=TalkingBook.pdf_catalog(TalkingBook.digitalizzati)
        send_data(pdf, :disposition=>'inline', :type=>'application/pdf')
      }
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
    # zipfile=@talking_book.zip_filepath(@clavis_patron)
    zipfile=@talking_book.zip_filepath(nil)
    if !File.exist?(zipfile)
      @talking_book.make_audio_zip(@clavis_patron)
    end
    fd=File.open("/home/storage/download_libro_parlato_da_opac.log", "a")
    fd.write("#{Time.now} - download #{File.basename(@talking_book.zip_filepath)} (record id: #{@talking_book.id}) per utente #{@clavis_patron.id}\n")
    fd.close
    send_file(zipfile)
  end
end
