class SpBibliographiesController < ApplicationController
  def index
    @h1_title='Proposte bibliografiche'
    @h2_title='Elenco cronologico'
    @css_id='bibliografie'

    qs=params[:qs]
    cond=[]
    if !qs.blank?
      ts=SpBibliography.connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('simple', description) @@ to_tsquery('simple', '#{ts}')"
    end
    # cond << "sp_bibliographies.status IN('A','C','N')"
    cond = cond.join(" AND ")

    @sp_bibliographies = SpBibliography.paginate(:conditions=>cond,
                                                 :page=>params[:page],
                                                 :include=>:sp_items,
                                                 :per_page=>10,
                                                 :order=>'sp_bibliographies.updated_at desc')

    respond_to do |format|
      format.html {
        render :layout=>params[:layout] if !params[:layout].blank?
      }
    end
  end

  def show
    @sp_bibliography=SpBibliography.find(params[:id])
    @h1_title='Proposte bibliografiche'
    @h1_link="/sp_bibliographies"
    @h2_title=@sp_bibliography.title[0..80]
    @css_id='bibliografie'
    render :layout=>params[:layout] if !params[:layout].blank?
  end

end
