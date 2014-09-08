class ClavisItemsController < ApplicationController
  def index
    # render :text=>params[:clavis_item].inspect
    # return
    @clavis_item = ClavisItem.new(params[:clavis_item])
    @attrib=@clavis_item.attributes.collect {|a| a if not a.last.blank?}.compact
    toskip=["item_order_status", "mediapackage_size", "usage_count", "renewal_count", "notify_count", "discount_value"]
    @attrib.delete_if do |r|
      toskip.include?(r.first)
    end
    # render :text=>@clavis_item.attributes
    # return
    cond=[]
    @clavis_items=[]
    @attrib.each do |a|
      name,value=a
      if name=='title'
        ts=ClavisItem.connection.quote_string(value.split.join(' & '))
        cond << "to_tsvector('simple', title) @@ to_tsquery('simple', '#{ts}')"
      else if name=='manifestation_id'
             cond << "manifestation_id=0" if value==1
           else
             ts=ClavisItem.connection.quote(value)
             cond << "#{name}=#{ts}"
           end
      end
    end
    cond = cond.join(" AND ")
    @sql_conditions=cond
    # @clavis_items = ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>100, :select=>'*',:joins=>"join clavis.lookup_value l on(l.value_class='ITEMMEDIATYPE' and l.value_key=item_media and value_language='it_IT')")
    order_by = cond.blank? ? nil : 'cc.sort_text'
    @clavis_items = ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>100, :select=>'item.*,l.value_label as item_media_type,cc.collocazione',:joins=>"left join clavis.collocazioni cc using(item_id) join clavis.lookup_value l on(l.value_class='ITEMMEDIATYPE' and l.value_key=item_media and value_language='it_IT')", :order=>order_by)
    respond_to do |format|
      format.html { render layout: 'navbar' }
      format.json { render json: @clavis_items }
    end
  end

  def show
    headers['Access-Control-Allow-Origin'] = "*"

    if params[:id]=='0'
      issue_id=params[:issue_id]
      sel="item_id,item_status,loan_class,section,collocation,inventory_serie_id,item_media"
      @clavis_item = ClavisItem.all(:select=>sel,:limit=>1,:conditions=>{:issue_id=>issue_id,:owner_library_id=>params[:owner_library_id]})
      if @clavis_item!=[]
        @clavis_item = @clavis_item.first
      else
        # @clavis_item=ClavisItem.first
        @clavis_item=nil
        if ClavisIssue.exists?(issue_id)
          ci=ClavisIssue.find(issue_id)
          @clavis_item = ClavisItem.first(:select=>sel,:conditions=>{:manifestation_id=>ci.manifestation_id,:owner_library_id=>params[:owner_library_id]})
        end
      end
    else
      @clavis_item=ClavisItem.find(params[:id])
      redirect_to @clavis_item.clavis_url and return if !params[:redir].blank?
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @clavis_item }
    end
  end

  def periodici_e_fatture
    year=params[:year].blank? ? '2014' : params[:year]
    library_id=params[:library_id].blank? ? 3 : params[:library_id]
    @clavis_items=ClavisItem.periodici_e_fatture(library_id,year)
    render layout: 'navbar'
  end

  def collocazioni
    headers['Access-Control-Allow-Origin'] = "*"

    mids=params[:mids]
    library_id=params[:library_id]
    library_id='' if library_id=='0'
    res={}
    sel='manifestation_id,section,collocation'
    cond="manifestation_id IN (#{mids.split.join(',')})"
    cond << " AND owner_library_id=#{library_id}" if !library_id.blank?

    #ClavisItem.find_all_by_manifestation_id(mids.split,:select=>sel).each do |r|
    #  res[r[:manifestation_id]]=r.collocazione
    #end

    sel='manifestation_id,section,collocation,specification,sequence1,sequence2'

    sql="SELECT #{sel} FROM clavis.item WHERE #{cond}"
    logger.warn(sql)
    ClavisItem.find_by_sql(sql).each do |r|
      res[r[:manifestation_id]]=r.collocazione
    end

    respond_to do |format|
      format.json { render :json => res }
    end
  end

end

