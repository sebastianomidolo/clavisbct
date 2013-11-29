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
    @clavis_item=ClavisItem.find(params[:id])
    redirect_to @clavis_item.clavis_url if !params[:redir].blank?
  end
end

