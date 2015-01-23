class ClavisItemsController < ApplicationController
  before_filter :authenticate_user!, only: 'showxxx'

  def index
    # render :text=>params[:clavis_item].inspect
    # return
    @clavis_item = ClavisItem.new(params[:clavis_item])
    if user_signed_in?
      @clavis_item.owner_library_id=2 if @clavis_item.owner_library_id.nil?
      if @clavis_item.current_container.nil?
        @clavis_item.current_container=user_session[:current_container]
      end
      user_session[:current_container]=@clavis_item.current_container
    end
    @attrib=@clavis_item.attributes.collect {|a| a if not a.last.blank?}.compact
    toskip=["item_order_status", "mediapackage_size", "usage_count", "renewal_count", "notify_count", "discount_value"]
    @attrib.delete_if do |r|
      toskip.include?(r.first)
    end

    cond=[]
    @clavis_items=[]
    @attrib.each do |a|
      name,value=a

      case name
      when 'title'
        ts=ClavisItem.connection.quote_string(value.split.join(' & '))
        cond << "to_tsvector('simple', title) @@ to_tsquery('simple', '#{ts}')"
      when 'manifestation_id'
        cond << "manifestation_id=0" if value==1
      when 'collocation'
        if (@clavis_item.collocation =~ /\.$/).nil?
          cond << "cc.collocazione = '#{@clavis_item.collocation}'"
          @sql_conditions = "uguale a '#{@clavis_item.collocation}'"
        else
          cond << "cc.collocazione ~ '^#{@clavis_item.collocation}'"
          @sql_conditions = "inizia con #{@clavis_item.collocation}"
        end
      else
        ts=ClavisItem.connection.quote(value)
        cond << "#{name}=#{ts}"
      end
    end
    if !params[:clavis_item].nil?
      @attrib << ['title','']
      @attrib << ['inventory_number','']
      if user_signed_in?
        @attrib << ['current_container', '']
        cond << 'label is not null' if @clavis_item.in_container=='1'
      end
      # cond << "cc.collocazione ~ '^#{params[:collocazione_inizia_per]}\\.'" if !params[:collocazione_inizia_per].blank?
      cond = cond.join(" AND ")
      # @sql_conditions=cond
      order_by = cond.blank? ? nil : 'cc.sort_text, clavis.item.title'
      @clavis_items = ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>100, :select=>'item.*,l.value_label as item_media_type,cc.collocazione,cont.label',:joins=>"left join clavis.collocazioni cc using(item_id) join clavis.lookup_value l on(l.value_class='ITEMMEDIATYPE' and l.value_key=item_media and value_language='it_IT') left join container_items cont using(item_id,manifestation_id)", :order=>order_by)
    else
      @clavis_items = ClavisItem.paginate_by_sql("SELECT * FROM clavis.item WHERE item_id=0", :page=>1);
    end

    respond_to do |format|
      format.html
      format.json { render json: @clavis_items }
    end
  end

  def ricollocazioni
    @clavis_item = ClavisItem.new(params[:clavis_item])
    cond=[]
    cond << "section in ('BCT09','BCT10','BCT11','BCT12','BCT13','BCT14','BCT15')"
    # cond << "section in ('BCT')"
    cond << "dewey_collocation ~ '^#{params[:dewey_collocation]}'" if !params[:dewey_collocation].blank?
    cond = cond.join(' AND ')
    # cond="section in ('BCT14')"
    @sql_conditions=cond
    @order_by = params[:sort] == 'dewey' ? 'dewey_collocation' : 'cc.sort_text'
    @clavis_items = ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>100,
                                        :select=>'item.*,r.*,cc.collocazione as full_collocation',
                                        :joins=>"join ricollocazioni r using(item_id) join clavis.collocazioni cc using(item_id)",
                                        :order=>@order_by)
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
      format.html
      format.js {
        if user_signed_in? and !current_user.google_doc_key.nil?
          @clavis_item.current_container=user_session[:current_container]
          if @clavis_item.current_container.blank?
            render :js=>"alert('Manca il numero del contenitore')"
          else
            if user_session[:google_session].nil?
              config = Rails.configuration.database_configuration
              username=config[Rails.env]["google_drive_login"]
              passwd=config[Rails.env]["google_drive_passwd"]
              session = GoogleDrive.login(username, passwd)
            else
              session=user_session[:google_session]
              user_session[:session_usage_count] = 1 if user_session[:session_usage_count].nil?
              user_session[:session_usage_count]+=1
            end
            s=session.spreadsheet_by_key(current_user.google_doc_key)
            ws=s.worksheets.first
            @usermessage=@clavis_item.save_in_google_drive(ws)
            ws.save
            user_session[:google_session]=session
          end
        end
      }
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

