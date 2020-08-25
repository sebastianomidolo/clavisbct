# coding: utf-8
class ClosedStackItemRequestsController < ApplicationController
  layout 'navbar'
  before_filter :set_dng_session, only: [:index, :check, :item_delete]

  load_and_authorize_resource only: [:index,:print,:confirm_request,:csir_delete, :csir_archive, :search]

  respond_to :html

  def index
    @pagetitle='Richieste a magazzino - Civica centrale'
    patron_id = params[:patron_id]
    pending = params[:pending]=='1' ? true : false
    printed = params[:printed]=='1' ? true : false
    today = params[:all].blank? ? true : false
    if !patron_id.blank?
      @patron = ClavisPatron.find(patron_id)
      @csir = ClosedStackItemRequest.list(@patron.id,pending,printed,today)
    end
    respond_to do |format|
      format.html {}
      format.js {
        render template:'closed_stack_item_requests/index'
      }
    end
  end

  def confirm_request
    @clavis_patron=ClavisPatron.find(params[:patron_id])
    n = ClosedStackItemRequest.list(@clavis_patron.id).size
    flash[:notice] = n==1 ? "Richiesta confermata" : "Confermate #{n} richieste"
    @daily_counter = ClosedStackItemRequest.assign_daily_counter(@clavis_patron, current_user.id)
    respond_to do |format|
      format.html { render text:'ok'}
      format.js { }
    end
  end

  def csir_delete
    # headers['Access-Control-Allow-Origin'] = '*'
    @csir=ClosedStackItemRequest.find(params[:id])
    @clavis_item = @csir.clavis_item
    m=@csir.attributes
    @csir.destroy
    @clavis_patron=ClavisPatron.find(@csir.patron_id)
    flash[:notice]="Cancellata richiesta per #{@clavis_item.to_label}"
    respond_to do |format|
      format.html { render text:"richiesta cancellata: #{m}" }
      format.js
    end
  end

  def csir_archive
    # headers['Access-Control-Allow-Origin'] = '*'
    @csir=ClosedStackItemRequest.find(params[:id])
    @clavis_item = @csir.clavis_item
    @clavis_patron=ClavisPatron.find(@csir.patron_id)
    @csir.archived=!(@csir.archived)
    @csir.save
    msg = @csir.archived==true ? "Archiviata" : "De-archiviata"
    flash[:notice]="#{msg} richiesta per #{@clavis_item.to_label}"
    respond_to do |format|
      format.html { render text:"richiesta archiviata" }
      format.js
    end
  end

  # Utilizzata solo via interfaccia utente DiscoveryNG per utente non loggato,
  # ma autentcato tramite dng_session
  # Per utente loggato usare csir_delete
  def item_delete
    headers['Access-Control-Allow-Origin'] = "*"
    respond_to do |format|
      format.html {render :text=>'cancellazione solo via js'}
      format.js {
        @target_div=params[:target_div]
        ir=ClosedStackItemRequest.find(params[:id])
        @orario = ir.confirm_time
        if ir.confirm_time.nil?
          logger.warn("destroy_closed_stack_item_request #{ir.id}")
          ir.destroy if !@dng_session.nil?
        else
          logger.warn("la richiesta con id #{ir.id} non può essere cancellata perché è già stata confermata")
        end
        # render template:'closed_stack_item_requests/deleted_ok'
        render template:'closed_stack_item_requests/check'
      }
    end
  end

  def check
    respond_to do |format|
      format.html
      format.js {
        @target_div=params[:target_div]
      }
      format.pdf  {
        filename="#{@dng_session.id}.pdf"
        patron=ClavisPatron.find(@dng_session.patron_id)
        pdf=patron.closed_stack_item_request_pdf(@dng_session)
        send_data(pdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
    end
  end

  def print
    @patron_id = params[:patron_id].blank? ? nil : ClavisPatron.find(params[:patron_id]).id
    if @patron_id.nil?
      render template:'closed_stack_item_requests/da_stampare'
      return
    end
    @reprint = params[:reprint]=='true' ? true : false
    # @records=ClosedStackItemRequest.richieste_magazzino(@patron_id,@reprint)
    @records=ClosedStackItemRequest.list(@patron_id,pending=false,printed=false,today=true,archived=false,reprint=@reprint)
    @totale_records=@records.size
    @records=@records[0..5]
    # @records=ClosedStackItemRequest.list(@patron_id,reprint=@reprint)
    respond_to do |format|
      format.html {
      }
      format.pdf {
        filename="elenco_richieste_a_magazzino.pdf"
        send_data(ClosedStackItemRequest.list_pdf(@records,@patron_id,@reprint),
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
        ClosedStackItemRequest.mark_as_printed(@records)
      }
    end
  end

  def autoprint_requests
    #require 'open3'
    #cmd = "/usr/bin/tail -60  /home/seb/autoprintweb.log | /usr/bin/tac"
    #a,b,c,d=Open3.popen3(cmd)
    #render text:"<pre>#{b.read}</pre>", layout:'navbar'
    @all=params[:all].blank? ? nil : true
  end

  def autoprint
    respond_to do |format|
      format.html {
        res=[];
        ClosedStackItemRequest.patrons(false,false).each do |r|
          res << r['patron_id']
        end
        res=res.join(' ')
        fd=File.open("/home/seb/autoprintweb.log", 'a')
        fd.write("#{Time.now} autoprint #{res}\n")
        fd.close
        render template:'closed_stack_item_requests/autoprint_list', layout:nil
      }
      format.pdf {
        @patron_id = ClavisPatron.find(params[:patron_id]).id
        @records=ClosedStackItemRequest.list(@patron_id,pending=false,printed=false,today=true,archived=false,reprint=false)
        @totale_records=@records.size
        @records=@records[0..5]
        filename="elenco_richieste_a_magazzino.pdf"
        send_data(ClosedStackItemRequest.list_pdf(@records,@patron_id,@reprint),
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
        ClosedStackItemRequest.mark_as_printed(@records)
      }
    end
  end

  def search
    @pagetitle='Ricerca richieste a magazzino - Civica centrale'
    if !params[:patron_id].blank?
      @patron=ClavisPatron.find(params[:patron_id])
    end
    @requests=ClosedStackItemRequest.logfile(params,@patron)
  end

  def stats
    @pagetitle='Statistiche ricerca richieste a magazzino - Civica centrale'
  end
  
  def random_insert
    ClosedStackItemRequest.random_insert
    redirect_to controller:'closed_stack_item_requests'
  end

  private
  def set_dng_session
    @dng_session=DngSession.find_by_params_and_request(params,request)
  end
  

end
