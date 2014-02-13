class AudioVisualsController < ApplicationController
  layout 'navbar'

  def index
    @audio_visual = AudioVisual.new(params[:audio_visual])
    fields=['titolo','autore','interpreti','tipologia','editore']
    cond=[]
    if !@audio_visual.collocazione.blank?
      cond << "replace(collocazione,' ','')=#{AudioVisual.connection.quote(@audio_visual.collocazione)}"
    end
    fields.each do |f|
      next if @audio_visual.send(f).blank?
      ts=AudioVisual.connection.quote_string(@audio_visual.send(f).split.join(' & '))
      cond << "to_tsvector('simple', #{f}) @@ to_tsquery('simple', '#{ts}')"
    end
    cond = cond.join(" AND ")
    @audio_visuals = AudioVisual.paginate(:conditions=>cond,:per_page=>300,:page=>params[:page], :order=>'espandi_collocazione(collocazione)')
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @audio_visuals }
    end
  end

  def show
    @audio_visual = AudioVisual.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @audio_visual }
      format.xml { render xml: @audio_visual }
    end
  end

end
