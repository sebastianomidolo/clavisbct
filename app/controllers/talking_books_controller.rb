# coding: utf-8
class TalkingBooksController < ApplicationController
  layout 'talking_books'
  # layout 'navbar'

  before_filter :set_talking_book, only: [:show, :edit, :update, :destroy]
  # load_and_authorize_resource only: [:edit,:check,:check_duplicates,:digitalizzati_non_presenti,:new,:create,:update,:destroy]
  load_and_authorize_resource except: [:index,:show,:download_mp3,:prenota]

  respond_to :html

  # GET /talking_books
  # GET /talking_books.json
  def index
    qs=params[:qs]
    @pagetitle='Catalogo del libro parlato BCT'

    # render :text=>'Catalogo del libro parlato non disponibile al momento', layout:'navbar' and return
    
    @talking_books_manager = true if can? :manage, TalkingBook
      
    cond=[]
    if !qs.blank?
      ts=TalkingBook.connection.quote_string(qs.split.join(' & '))
      tsvector=[]
      ['intestatio','titolo','respons', 'n'].each do |fld|
        tsvector << fld
      end

      tsvector = %Q{to_tsvector(#{tsvector.join(" || ' ' || ")})}

      # cond << "to_tsvector('simple', titolo) @@ to_tsquery('simple', '#{ts}') or to_tsvector('simple', intestatio) @@ to_tsquery ('simple','#{ts}')"
      cond << "#{tsvector} @@ to_tsquery('english', '#{ts}')"
      # render text:cond.join(' ')  and return
    end

    cond << "talking_book_reader_id = #{params[:talking_book_reader_id]}" if !params[:talking_book_reader_id].blank?
    
    # Sovrascrivo parametri per accesso anonimo
    if !@talking_books_manager
      params[:digitalized]='yes' if params[:digitalized].blank?
      type=params[:audiocassette]
      if type!='yes'
        cond << "d_objects_folder_id notnull"
      end
    else
      type=params[:digitalized]
      if type=='yes'
        # logger.warn("type: solo digitalizzati")
        # cond << "digitalizzato notnull"
        cond << "d_objects_folder_id notnull"
      end
    end
    
    type=params[:cdmp3]
    if type=='yes'
      cond << "cd notnull and digitalizzato notnull and da_inserire_in_informix='0'"
    end
    type=params[:lettore]
    if type=='yes'
      cond << "lettore notnull and talking_book_reader_id is null"
    end
    if @talking_books_manager
      type=params[:colloc]
      if type=='yes'
        cond << "n is null"
      else
        cond << "n is not null"
      end
    else
      cond << "n is not null"
    end

    type=params[:novita]
    if type=='yes'
      mesi = params[:mesi].blank? ? 12 : params[:mesi].to_i
      mesi = 12 if mesi==0
      cond << "data_collocazione > now() - interval '#{mesi} months'"
    end
    # Ordinamento per amministratore:
    if @talking_books_manager
      order = 'id desc'
    else
      if params[:qs].blank?
        if params[:type]=='novita'
          order='id desc'
        else
          order='chiave,ordine'
          order='id desc'
          # order = 'digitalizzato desc'
          order = 'digitalizzato desc nulls last, id desc'
        end
      else
        order='chiave,ordine'
      end
    end

    respond_to do |format|
      format.html {
        if params[:htmloutput]=='yes'
          cond << "n != ''"
          cond = cond.join(" AND ")
          @talking_books = TalkingBook.find(:all,:conditions=>cond, :order=>order)
          render :partial=>'talking_books/html_catalog'
          return
        else
          # @talking_books = TalkingBook.paginate(:conditions=>cond,:page=>params[:page], :include=>[:clavis_item])
          joins = [:clavis_items]
          joins = []
          cond = cond.join(" AND ")
          if @talking_books_manager
            sql=%Q{
          select tb.*,
  array_to_string(array_agg(ci.collocation order by item_id), '|') as collocations,
  array_to_string(array_agg(ci.manifestation_id order by item_id), '|') as manifestation_ids,
  array_to_string(array_agg(ci.item_id order by item_id), '|') as item_ids,
  array_to_string(array_agg(ci.opac_visible order by item_id), '|') as opac_visibilities,
  array_to_string(array_agg((xpath('//d215/sa/text()',cm.unimarc::xml))[1]::text order by item_id), '|') AS descr_fisica,
  count(*)
    from libroparlato.catalogo as tb left join clavis.item ci on(ci.talking_book_id=tb.id and ci.item_media = 'T')
    left join clavis.manifestation cm on(cm.manifestation_id=ci.manifestation_id)
    where #{cond}
     group by tb.id
    order by #{order}}
          else
            sql=%Q{
          select tb.*,
  array_to_string(array_agg(ci.collocation order by item_id), '|') as collocations,
  array_to_string(array_agg(ci.manifestation_id order by item_id), '|') as manifestation_ids,
  array_to_string(array_agg(ci.item_id order by item_id), '|') as item_ids,
  array_to_string(array_agg(ci.opac_visible order by item_id), '|') as opac_visibilities,
  array_to_string(array_agg((xpath('//d215/sa/text()',cm.unimarc::xml))[1]::text order by item_id), '|') AS descr_fisica,
  count(*)
    from libroparlato.catalogo as tb join clavis.item ci on(ci.talking_book_id=tb.id)
    join clavis.manifestation cm on(cm.manifestation_id=ci.manifestation_id)
    where ci.item_media = 'T' and #{cond}
     group by tb.id
    order by #{order}}
          end

          # render text:sql and return

          @talking_books = TalkingBook.paginate_by_sql(sql, page:params[:page])
        end
        render :index, layout:'talking_books' if @talking_books_manager
      }

      format.js {
        # @talking_books = TalkingBook.find(:all,:conditions=>cond, :order=>order)
        @talking_books = TalkingBook.paginate(:conditions=>cond,:page=>params[:page],:order=>order)
      
        @targetdiv=params[:targetdiv]
      }

      format.csv {
        require 'csv'
        cond << "titolo != ''"
        cond = cond.join(" AND ")
        @records = TalkingBook.find(:all,:conditions=>cond, :order=>"chiave, ordine")
        csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
          csv << ["Chiave", "Ordine", "Autore", "Responsabilità", "Titolo", "Numero CD", "Collocazione", "Numero cassette",
                  "Data digitalizzazione", "RecordID", "Abstract", "Data collocazione", "ManifestationId"]
          @records.each do |r|
            # barcode = r.clavis_item.nil? ? "da controllare" : r.clavis_item.barcode
            barcode = ''
            csv << [r.chiave,r.ordine,r.intestatio,r.respons,r.titolo.strip,r.cd,r.n,r.cassette,
                    r.digitalizzato,r.id,r.abstract,r.data_collocazione,r.manifestation_id]
          end
        end
        # send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=libriparlati_scaricabili.csv"
        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=talking_books.csv"
      }

      format.pdf {
        cond = cond.join(" AND ")
        @talking_books = TalkingBook.find(:all,:conditions=>cond, :order=>order)
        pdf=TalkingBook.pdf_catalog(@talking_books)
        send_data(pdf, :disposition=>'inline', :type=>'application/pdf')
      }

    end
  end

  # GET /talking_books/1
  # GET /talking_books/1.json
  def show
    respond_to do |format|
      format.html { render :show }
      format.json { render json: @talking_book }
    end
  end

  def edit
    # render layout:'navbar'
  end

  def make_zip
    @talking_book.create_or_replace_audio_zip
    # make_audio_zip
    redirect_to edit_talking_book_path
  end

  def delete_zip
    if File.exists?(@talking_book.zip_filepath)
      File.delete(@talking_book.zip_filepath)
    end
    redirect_to edit_talking_book_path
  end
  
  def new
    @talking_book = TalkingBook.new
    render layout:'navbar'
  end

  def create
    @talking_book = TalkingBook.new(params[:talking_book])
    @talking_book.save
    respond_with(@talking_book)
  end

  def update
    @talking_book.update_attributes(params[:talking_book])
    respond_with(@talking_book)
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

  def digitalizzati_non_presenti
    @talking_books=TalkingBook.digitalizzati_non_presenti_su_server
  end

  def build_pdf
    require 'open3'
    @stdout,@stderr,@status=TalkingBook.build_pdf_catalogs
  end

  def prenota
    ack=DngSession.access_control_key(params,request)
    if ack!=params[:ac]
      render :text=>"error - params: #{params} - request: #{request}", :content_type=>'text/plain'
      return
    end
    render text:"prenotare #{params}"
  end

  def download_mp3
    ack=DngSession.access_control_key(params,request)
    if ack!=params[:ac]
      render :text=>"error - params: #{params} - request: #{request}", :content_type=>'text/plain'
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

  def search

    digitalizzati = "and d_objects_folder_id notnull"
    
    if params[:listaautoretitolo]=='1'
      cnd=params[:lettera].blank? ? '' : "and intestatio ~* '^#{TalkingBook.connection.quote_string(params[:lettera])}'"
      sql="select * from libroparlato.catalogo where manifestation_id notnull #{digitalizzati} #{cnd} order by chiave,ordine"
      @talking_books=TalkingBook.paginate_by_sql(sql, page:1, per_page:9999)
    end
    cond=[]
    cond << "intestatio ~* #{TalkingBook.connection.quote(params[:autore])}" if !params[:autore].blank?
    cond << "titolo ~* #{TalkingBook.connection.quote(params[:titolo])}" if !params[:titolo].blank?
    cond << "lower(n)=lower(#{TalkingBook.connection.quote(params[:inventario])})" if !params[:inventario].blank?
    if cond.size>0
      sql="select * from libroparlato.catalogo where manifestation_id notnull and #{cond.join(' AND ')} order by chiave,ordine"
      @talking_books=TalkingBook.paginate_by_sql(sql, page:1, per_page:9999)
    end
    
    @talking_books=TalkingBook.paginate_by_sql("select * from #{TalkingBook.table_name} where false", page:1) if @talking_books.nil?    
    # render layout:'libroparlato'
    render layout:'lpmask'
  end

  def check
    # render layout:'navbar'
  end

  def stats
  end

  def opac_edit_intro
    if request.post?
      # render text:params[:html_intro] and return
      html = TalkingBook.connection.quote(params[:html_text])
      TalkingBook.connection.execute("update libroparlato.opac set html_intro=#{html} where html_id='a'")
    end
    @record=TalkingBook.connection.execute("select html_intro from libroparlato.opac where html_id='a'").to_a.first
  end

  private
  def set_talking_book
    @talking_book = TalkingBook.find(params[:id])
  end
  
end
