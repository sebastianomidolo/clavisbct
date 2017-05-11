# coding: utf-8
class ClavisItemsController < ApplicationController
  before_filter :authenticate_user!, only: 'showxxx'
  load_and_authorize_resource only: [:index,:ricollocazioni]

  def index
    @clavis_item = ClavisItem.new(params[:clavis_item])

    if can? :search, ClavisItem
      if @clavis_item.owner_library_id.nil?
        librarian=current_user.clavis_librarian
        if librarian.nil?
          @clavis_item.owner_library_id=2
        else
          @clavis_item.owner_library_id=librarian.default_library_id
        end
      end
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
          if @clavis_item.collocation.count(' ')>0
            cond << "cc.collocazione = upper(replace('#{@clavis_item.collocation.squeeze(' ')}',' ','.'))"
          else
            cond << "cc.collocazione ~* '^#{@clavis_item.collocation}'"
          end
          @sql_conditions = "inizia con '#{@clavis_item.collocation}'"
        else
          cond << "cc.collocazione ~ '^#{@clavis_item.collocation}'"
          @sql_conditions = "inizia con #{@clavis_item.collocation}"
        end
      when 'rfid_code'
        if !@clavis_item.rfid_code.nil?
          cond << (@clavis_item.rfid_code=='1' ? "rfid_code !=''" : "(rfid_code is null OR rfid_code='')")
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
        cond << 'containers.label is not null' if @clavis_item.in_container=='1'
      end

      if !params[:days].blank?
        cond << "date_updated between now() - interval '#{params[:days]} days' and now()"
      end
      cond = cond.join(" AND ")
      @sql_conditions=cond
      order_by = cond.blank? ? nil : 'cc.sort_text, clavis.item.title'
      @clavis_items = ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>135, :select=>'item.*,l.value_label as item_media_type,ist.value_label as item_status,lst.value_label as loan_status,cc.collocazione,containers.label',:joins=>"left join clavis.collocazioni cc using(item_id) left join clavis.lookup_value l on(l.value_class='ITEMMEDIATYPE' and l.value_key=item_media and value_language='it_IT') left join clavis.lookup_value ist on(ist.value_class='ITEMSTATUS' and ist.value_key=item_status and ist.value_language='it_IT') left join clavis.lookup_value lst on(lst.value_class='LOANSTATUS' and lst.value_key=loan_status and lst.value_language='it_IT') left join container_items cont using(item_id,manifestation_id) left join containers on (containers.id=cont.container_id)", :order=>order_by)
    else
      @clavis_items = ClavisItem.paginate_by_sql("SELECT * FROM clavis.item WHERE false", :page=>1);
    end

    respond_to do |format|
      format.html
      format.csv {
        page=params[:page].blank? ? '' : "_pagina_#{params[:page]}"
        fname = "barcodes#{page}.csv"
        csv_data=@clavis_items.collect {|x| x.barcode}
        send_data csv_data.join("\n"), type: Mime::CSV, disposition: "attachment; filename=#{fname}"
      }
      format.pdf {
        filename="#{@clavis_items.size}_segnaposto.pdf"
        lp=LatexPrint::PDF.new('labels', @clavis_items)
        send_data(lp.makepdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
      format.json { render json: @clavis_items }
    end
  end

  def ricollocazioni
    @onshelf = params[:onshelf]
    @formula = params[:formula]
    @formula2 = params[:formula2]
    @collocation = params[:collocation]
    @dest_section = params[:dest_section]
    @dest_section_label=OpenShelfItem.label(@dest_section)
    @clavis_item = ClavisItem.new(params[:clavis_item])
    @sections=params[:sections]
    @sort=params[:sort]
    @dewey=params[:dewey_collocation]

    @clavis_items = ClavisItem.items_ricollocati(params)

    respond_to do |format|
      format.html
      format.csv {
        csv_data=@clavis_items.collect {|x| "#{x[:full_collocation]}\t#{x[:title].strip[0..32]}\t#{x[:inventory_number]}\t#{x[:item_id]}" }
        send_data csv_data.join("\n"), type: Mime::CSV, disposition: "attachment; filename=clavis_items.csv"
      }
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
          @clavis_item = ClavisItem.first(:select=>sel,:conditions=>{:manifestation_id=>ci.manifestation_id,:owner_library_id=>params[:owner_library_id], :item_status=>'F'})
        end
      end
    else
      @clavis_item=ClavisItem.find(params[:id])
      redirect_to @clavis_item.clavis_url and return if !params[:redir].blank?
    end
    respond_to do |format|
      format.html
      format.js {
        if can? :manage, Container
          @clavis_item.current_container=user_session[:current_container]
          if @clavis_item.current_container.blank?
            @usermessage="Manca il numero del contenitore"
          else
            @usermessage=@clavis_item.save_in_container(current_user,Container.find_or_create_by_label(user_session[:current_container]))
          end
        end
      }
      format.json { render :json => @clavis_item }
    end
  end

  def info
    @clavis_item=ClavisItem.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def sync
    @clavis_item=ClavisItem.new(params[:i])
    @clavis_item.id=params[:id]
    new_item_status=ClavisItem.item_status_label_to_key(@clavis_item.item_status)
    new_loan_status=ClavisItem.loan_status_label_to_key(@clavis_item.loan_status)
    new_section=ClavisItem.section_label_to_key(@clavis_item.section,@clavis_item.owner_library_id)
    new_custom_field1=@clavis_item.custom_field1
    new_collocation=@clavis_item.collocation
    if ClavisItem.exists?(params[:id])
      @clavis_item=ClavisItem.find(params[:id])
      @clavis_item.item_status=new_item_status
      @clavis_item.loan_status=new_loan_status
      @clavis_item.section=new_section
      @clavis_item.collocation=new_collocation
      @clavis_item.custom_field1=new_custom_field1
      @clavis_item.save if @clavis_item.changed?
    else
      @clavis_item.item_status=new_item_status
      @clavis_item.loan_status=new_loan_status
      @clavis_item.section=new_section
      @clavis_item.item_icon=''
      @clavis_item.issue_number=0
      @clavis_item.section=@clavis_item.section.split.first
      @clavis_item.save
    end
    respond_to do |format|
      format.html
      format.js
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
    # logger.warn(sql)
    ClavisItem.find_by_sql(sql).each do |r|
      res[r[:manifestation_id]]=r.collocazione
    end

    respond_to do |format|
      format.json { render :json => res }
    end
  end

  def closed_stack_item_request
    # headers['Access-Control-Allow-Origin'] = "*"
    headers['Access-Control-Allow-Origin'] = "http://bct.comperio.it"
    cm=ClavisManifestation.find(params[:manifestation_id])
    patron=ClavisPatron.find_by_opac_username(params[:dng_user])
    dng_session=DngSession.find_by_params_and_request(params,request)
    library_id=params[:library_id]
    s,i=params[:inventario].split('-')
    if i.blank?
      collocazione=params[:collocazione].gsub(' ', '.')
      logger.warn("richiesta_a_magazzino senza inventario, collocazione: #{collocazione}")
      sql=%Q{SELECT ci.* FROM clavis.collocazioni cc JOIN clavis.item ci USING(item_id)
         WHERE cc.collocazione=#{ClavisItem.connection.quote(collocazione)}}
      item=ClavisItem.find_by_sql(sql).first
    else
      item=ClavisItem.find_by_home_library_id_and_inventory_serie_id_and_inventory_number(library_id,s,i)
    end
    if patron.closed_stack_item_requests.collect {|r| r.item_id}.include?(item.id)
      render json:{status:'presente', msg:"Esemplare precedentemente già richiesto"}
    else
      logger.warn("richiesta_a_magazzino #{cm.title}")
      logger.warn("richiesta_a_magazzino #{patron.lastname}")
      logger.warn("richiesta_a_magazzino #{patron.opac_username}")
      logger.warn("richiesta_a_magazzino #{dng_session.inspect}")
      logger.warn("richiesta_a_magazzino #{item.id}")
      logger.warn("richiesta_a_magazzino #{item.title}")
      ClosedStackItemRequest.create(item_id:item.id,patron_id:patron.id,dng_session_id:dng_session.id,request_time:Time.now)
      render json:{status:'ok', requests:ClosedStackItemRequest.count, msg:'Richiesta recepita'}
    end
  end

  def fifty_years
    @clavis_items=ClavisItem.fifty_years(params)
  end

  def controllo_valori_inventariali
    @clavis_items=ClavisItem.controllo_valori_inventariali(params)
  end

end

