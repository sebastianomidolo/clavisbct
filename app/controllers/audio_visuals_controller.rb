class AudioVisualsController < ApplicationController
  layout 'navbar'

  def index
    qs=params[:qs]
    cond=[]
    cond << "collocazione!=''"
    if !qs.blank?
      ts=AudioVisual.connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('simple', titolo) @@ to_tsquery('simple', '#{ts}') OR to_tsvector('simple', autore) @@ to_tsquery('simple', '#{ts}')"
    end
    cond = cond.join(" AND ")

    @audio_visuals = AudioVisual.paginate(:conditions=>cond,:page=>params[:page], :order=>'espandi_collocazione(collocazione)')

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
