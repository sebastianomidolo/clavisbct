class IssArticlesController < ApplicationController
  layout 'navbar'

  def index
    qs=params[:qs]
    cond=[]
    if !qs.blank?
      ts=IssArticle.connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('simple', title) @@ to_tsquery('simple', '#{ts}')"
    end
    cond = cond.join(" AND ")

    @iss_articles = IssArticle.paginate(:conditions=>cond,:page=>params[:page], :include=>[:pages])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @iss_articles }
    end
  end

  def show
    @iss_article = IssArticle.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @iss_article }
    end
  end

end
