class SpBibliographiesController < ApplicationController
  def index
    qs=params[:qs]
    cond=[]
    if !qs.blank?
      ts=SpBibliography.connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('simple', title) @@ to_tsquery('simple', '#{ts}')"
    end
    cond = cond.join(" AND ")

    @sp_bibliographies = SpBibliography.paginate(:conditions=>cond,:page=>params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def show
    @sp_bibliography=SpBibliography.find(params[:id])
  end

end
