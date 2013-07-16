class ClavisItemsController < ApplicationController
  def index
    qs=params[:qs]
    cond=[]
    @clavis_items=[]
    if !qs.blank?
      ts=ClavisItem.connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('simple', title) @@ to_tsquery('simple', '#{ts}')"
      cond << "manifestation_id=0"
      cond << "owner_library_id=3"
      cond = cond.join(" AND ")
      @clavis_items = ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>100, :select=>'*',:joins=>"join clavis.lookup_value l on(l.value_class='ITEMMEDIATYPE' and l.value_key=item_media and value_language='it_IT')")
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @clavis_items }
    end
  end

  def show
    @clavis_item=ClavisItem.find(params[:id])
    redirect_to @clavis_item.clavis_url if !params[:redir].blank?
  end
end

