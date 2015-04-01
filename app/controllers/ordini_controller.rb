class OrdiniController < ApplicationController
  layout 'navbar'

  def index
    @ordine=Ordine.new(params[:ordine])
    @ordine.ordanno=Time.now.year if @ordine.ordanno.blank?
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
      when 'CES'
        cond << "sat.stato='Cessata'"
      when 'NDC'
        cond << "sat.fattura_o_nota_di_credito='N'"
      when 'RIT'
        cond << "sat.stato='In Ritardo'"
      when 'ARCPER'
        cond << "sat.ordnum is null"
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
      when 'AUA'
        cond << "issue_status IN('A','U')"
      else
        cond << "issue_status='#{@ordine.issue_status}'"
      end
    end
    if params[:ordine].nil?
      @ordini=[]
    else
      cond = cond.join(" AND ")
      @sql_conditions=cond
      @ordini=ClavisManifestation.periodici_ordini(@ordine,params[:page],200,cond)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ordini }
    end
  end

  def fatture
    @library=ClavisLibrary.find(params[:library_id]) if !params[:library_id].blank?
    @ordanno=params[:ordanno]
    if params[:numero_fattura].blank?
      @fatture=Ordine.fatture(@library,@ordanno)
    else
      @ordine = Ordine.new(:library_id=>@library.id)
      @ordine.numero_fattura=params[:numero_fattura]
      @ordini=ClavisManifestation.periodici_ordini(@ordine,params[:page],100)
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
