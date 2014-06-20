class OrdiniController < ApplicationController
  layout 'navbar'

  def index
    @ordine=Ordine.new(params[:ordine])
    @pagetitle="Ordini periodici"
    @pagetitle << " - #{@ordine.clavis_library.shortlabel}" if !@ordine.clavis_library.nil?
    cond=[]
    if !@ordine.titolo.blank?
      @pagetitle << " - ricerca per parole: '#{@ordine.titolo}'"
      ts=Ordine.connection.quote_string(@ordine.titolo.split.join(' & '))
      cond << "to_tsvector('simple', titolo) @@ to_tsquery('simple', '#{ts}')"
    end
    if !@ordine.issue_status.blank?
      case @ordine.issue_status
      when 'SM'
        cond << "sat.manifestation_id is null"
      when 'NIC'
        cond << "issue_status is null"
      when 'NICNF'
        cond << "issue_status is null and sat.numero_fattura is null"
      when 'NICF'
        cond << "issue_status is null and sat.numero_fattura is not null"
      when 'FATT'
        cond << "sat.numero_fattura is not null"
      when 'NFATT'
        cond << "sat.numero_fattura is null"
      else
        cond << "issue_status='#{@ordine.issue_status}'"
      end
    end
    cond = cond.join(" AND ")
    @sql_conditions=cond
    @ordini=ClavisManifestation.periodici_ordini(@ordine,params[:page],200,cond)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ordini }
    end
  end

  def fatture
    @library=ClavisLibrary.find(params[:library_id])
    @ordine = Ordine.new(:library_id=>@library.id)
    if params[:numero_fattura].blank?
      @fatture=Ordine.fatture(@library.id)
    else
      @ordine.numero_fattura=params[:numero_fattura]
      @ordini=ClavisManifestation.periodici_ordini(@ordine,params[:page],10)
    end
  end

  def show
    @ordine = Ordine.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ordine }
    end
  end
end
