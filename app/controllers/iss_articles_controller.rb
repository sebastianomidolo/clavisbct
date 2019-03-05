class IssArticlesController < ApplicationController
  layout 'iss_journals'

  def index
    qs=params[:qs]
    @cond=[]
    if !qs.blank?
      qs_saved=String.new(qs)
      qs.gsub!(' ', '<->') if qs =~ /^\"/
      ts=IssArticle.connection.quote_string(qs.split.join(' & '))
      params[:qs]=qs_saved
      @cond << "to_tsvector('simple', a.title) @@ to_tsquery('simple', '#{ts}')"
    end
    @cond = @cond.join(" AND ")
    order_by = 'order by j.title, i.annata, a.title'
    @cond = 'false' if @cond.blank?

    @sql=%Q{SELECT i.annata || '-' || i.fascicolo as annata,a.title as article_title,j.title as journal_title,
          j.id as journal_id,
          i.id as issue_id,
          a.id as article_id
            FROM iss.articles a
             JOIN iss.issues i on(i.id=a.issue_id)
             JOIN iss.journals j on(j.id=i.journal_id)
             WHERE #{@cond} #{order_by}}

    @iss_articles = IssArticle.paginate_by_sql(@sql,:page=>params[:page], :per_page=>25)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @iss_articles }
    end
  end

  def show
    @iss_article = IssArticle.find(params[:id])
    @iss_issue=@iss_article.issue
    respond_to do |format|
      format.html
      format.js
      format.json {render text:@iss_article.to_json}
      format.pdf {
        @iss_article.prepara_pdf_completo if !@iss_article.esiste_pdf_cached?
        send_file(@iss_article.pdf_cached_fname, :filename=>"#{@iss_article.title}.pdf",
                  :type=>'application/pdf', :disposition => 'inline')
      }
    end
  end

end
