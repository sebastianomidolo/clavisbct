# coding: utf-8
include TextSearchUtils

class ClavisItemsController < ApplicationController
  before_filter :authenticate_user!, only: 'showxxx'
  load_and_authorize_resource only: [:index,:ricollocazioni]

  def index
    if !params[:home_library_id].blank?
      render template: '/clavis_items/group_by' and return 
    end
    @pagetitle='Ricerca esemplari ClavisBCT'
    @clavis_item = ClavisItem.new(params[:clavis_item])

    
    if params[:shelf_id].blank?
      join_shelfs=''
    else
      join_shelfs=" join clavis.shelf_item si on(si.object_class='item' and si.shelf_id=#{params[:shelf_id].to_i} and si.object_id=clavis.item.item_id)"
    end

    if can? :search, ClavisItem
      if @clavis_item.home_library_id.nil?
        librarian=current_user.clavis_librarian
        if librarian.nil?
          @clavis_item.home_library_id=2
        else
          @clavis_item.home_library_id=librarian.default_library_id
        end
      end
      if @clavis_item.current_container.nil?
        @clavis_item.current_container=user_session[:current_container]
      end
      user_session[:current_container]=@clavis_item.current_container
    end
    @clavis_item.home_library_id=params[:library_id] if !params[:library_id].blank?

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
        # ts=ClavisItem.connection.quote_string(value.split.join(' & '))
        ts=ClavisItem.connection.quote_string(textsearch_sanitize(value))
        cond << "to_tsvector('simple', clavis.item.title) @@ to_tsquery('simple', '#{ts}')"
      when 'manifestation_id'
        cond << "manifestation_id=0" if value.blank?
      when 'home_library_id'
        if params[:item_ids].blank?
          cond << "item.home_library_id=#{value}" if value!=0
        end
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
        if value=~/^!/
          x=value.sub(/^!/,'')
          cond << "item.#{name}!=#{ClavisItem.connection.quote(x)}"
        else
          cond << "item.#{name}=#{ClavisItem.connection.quote(value)}"
        end
      end
    end

    join_clavis_loans=''
    if !params[:sql_and].blank?
      sql_and = read_sql_and(params[:sql_and])
      cond << sql_and
      join_clavis_loans=' join clavis.loan using(item_id)' if params[:sql_and] =~ /loan\./i
    end
    if !params[:manifestation_ids].blank? and !params[:library_id].blank?
      items=ClavisItem.esemplari_disponibili(params[:manifestation_ids],params[:library_id])
      items=items.split.join(' ')
      if params[:item_ids].blank?
        params[:item_ids] = items
      else
        params[:item_ids] += items
      end
    end
    
    if !params[:clavis_item].nil? or !params[:item_ids].blank? or !params[:senzapiano].blank? or !params[:piano].blank?
      @attrib << ['title','']
      @attrib << ['inventory_number','']
      if user_signed_in?
        @attrib << ['current_container', '']
        cond << 'containers.label is not null' if @clavis_item.in_container=='1'
      end

      if !params[:days].blank?
        cond << "date_updated between now() - interval '#{params[:days]} days' and now()"
      end

      select_item_requests=join_item_requests=''
      if !params[:item_ids].blank?
        if !params[:request_date].blank?
          user_session[:item_ids]=nil
        end
        item_ids=params[:item_ids].split
        item_ids=item_ids.collect {|x| x.to_i if !x.blank?}
        if user_session[:item_ids].blank?
          user_session[:item_ids]=item_ids
        else
          user_session[:item_ids] = user_session[:item_ids] | item_ids
        end
        cond << "clavis.item.item_id IN(#{user_session[:item_ids].join(',')})"
        if !params[:request_date].blank?
          req_date = ClavisItem.connection.quote(params[:request_date])
          join_item_requests=%Q{ LEFT JOIN LATERAL (select to_char(request_date,'FMDD/FMMM/YYYY HH24:MI') as request_date,
                     cp.name as patron_name,cp.lastname as patron_lastname,cp.barcode as patron_barcode,
                     cp.patron_id as patron_patron_id
                  FROM clavis.item_request JOIN clavis.patron cp using(patron_id)
                WHERE request_date::char(10)=#{req_date} AND item_id=clavis.item.item_id ORDER BY request_date limit 1) cir on true}
          select_item_requests="cir.*,"
        end
      end

      if !params[:include_item_requests].blank?
        join_item_requests=%Q{ JOIN LATERAL (select to_char(request_date,'FMDD/FMMM/YYYY HH24:MI') as request_date,
                     cp.name as patron_name,cp.lastname as patron_lastname,cp.barcode as patron_barcode,
                     cp.patron_id as patron_patron_id
                  FROM clavis.item_request JOIN clavis.patron cp using(patron_id)
                WHERE request_date::char(10)='2020-06-22' and item_id=clavis.item.item_id ORDER BY request_id desc limit 1) cir on true}
        select_item_requests="cir.*,"
      end

      if params[:senzapiano]=='y'
        #cond << %Q{piano is null and ((home_library_id != -3 and manifestation_id!=0 and item_status IN ('F','G','S'))
        #         OR (home_library_id = -1 and owner_library_id=2)) }
        cond << %Q{(piano='__non assegnato__' or piano is null) and ((item.home_library_id = 2 and item_status IN ('F','G','S'))
                 OR (item.home_library_id=2 and owner_library_id=-1)) }
      end

      if !params[:piano].blank?
        cond << %Q{piano=#{ClavisItem.connection.quote(params[:piano])}}
      end

      if params[:cover_images].blank?
        join_cover_images=select_cover_images=''
      else
        cond << "item.manifestation_id>0"
        if params[:cover_images]=='f'
          # cond << %Q{covers is null and (cm."EAN" is null or cm."EAN"='')}
          cond << "covers is null"
        else
          cond << "covers is not null"
        end
        jointype = params[:cover_images]=='t' ? 'JOIN' : 'LEFT JOIN'
        jointype = 'left join'
        join_cover_images = %Q{#{jointype} LATERAL (SELECT * FROM clavis.attachment WHERE object_id=item.manifestation_id
             AND object_type='Manifestation' and attachment_type='E' limit 1) as covers on true }
        select_cover_images='covers.attachment_id as cover_id,'
      end

      join_with_manifestations=select_with_manifestations=''
      if !params[:with_manifestations].blank? or !params[:ean_presence].blank?
        cond << "item.manifestation_id>0"
        if params[:ean_presence]=='t'
          cond << %Q{ ((cm."EAN" != '') OR (cm."ISBNISSN" != '')) }
        else
          cond << %Q{ (cm."EAN" is null or cm."EAN"='') AND (cm."ISBNISSN" is null or cm."ISBNISSN"='') }
        end
        join_with_manifestations = %Q{LEFT JOIN clavis.manifestation cm using(manifestation_id)}
        select_with_manifestations=%Q{cm."EAN" as ean,cm."ISBNISSN" as isbnissn,cm.publisher,cm.edition_date,(xpath('//d210/sa/text()',cm.unimarc::xml))[1] as luogo_di_pubblicazione,}
      end

      cond = cond.join(" AND ")
      @sql_conditions=cond if current_user.email=='seba'
      if @clavis_item.item_media=='S'
        order_by = 'clavis.item.manifestation_id, clavis.item.issue_year,clavis.item.issue_number'
      else
        if params[:order]=='collocation'
          order_by = 'cc.sort_text, clavis.item.title'
        else
          if !@clavis_item.created_by.nil? or !@clavis_item.modified_by.nil?
            if @clavis_item.modified_by.nil?
              order_by = 'clavis.item.date_created::date desc, cc.sort_text, clavis.item.title'
            else
              order_by = 'clavis.item.date_updated::date desc, cc.sort_text, clavis.item.title'
            end
          else
            order_by = cond.blank? ? nil : 'cl.piano, cc.sort_text, clavis.item.title'
          end
        end
      end
      # order_by = cond.blank? ? nil : 'cc.sort_text, clavis.item.title'
      if params[:con_prenotazioni].blank?
        join_prenotazioni=select_prenotazioni=''
      else
        join_prenotazioni='join clavis.items_con_prenotazioni_pendenti icpp using(item_id)'
        select_prenotazioni='icpp.*,'
      end
      if params[:unique_items].blank?
        join_unique_items=''
      else
        join_unique_items=' join clavis.unique_items using(item_id)'
      end

      qparm={
        conditions:cond,
        page:params[:page],
        per_page:params[:per_page].blank? ? 135 : params[:per_page],
      }
      qparm[:select]="#{select_with_manifestations}#{select_cover_images}#{select_prenotazioni}#{select_item_requests}item.*,l.value_label as item_media_type,ist.value_label as item_status,lst.value_label as loan_status,cc.collocazione,cl.piano,containers.label,ec.note_interne"
      qparm[:joins]="#{join_with_manifestations}#{join_cover_images}#{join_prenotazioni}left join clavis.collocazioni cc using(item_id) left join clavis.centrale_locations cl using(item_id) left join clavis.lookup_value l on(l.value_class='ITEMMEDIATYPE' and l.value_key=item_media and value_language='it_IT') left join clavis.lookup_value ist on(ist.value_class='ITEMSTATUS' and ist.value_key=item_status and ist.value_language='it_IT') left join clavis.lookup_value lst on(lst.value_class='LOANSTATUS' and lst.value_key=loan_status and lst.value_language='it_IT') left join #{ExtraCard.table_name} ec on (custom_field3=ec.id::varchar) left join container_items cont using(item_id,manifestation_id) left join containers on (containers.id=cont.container_id or containers.id=ec.container_id)#{join_unique_items}#{join_clavis_loans}#{join_shelfs}#{join_item_requests}"
      qparm[:order]=order_by      

      @clavis_items = ClavisItem.paginate(qparm)

      @sql_conditions = qparm.inspect if current_user.email=='seba'
    else
      @clavis_items = ClavisItem.paginate_by_sql("SELECT * FROM clavis.item WHERE false", :page=>1);
    end

    if !user_session[:item_ids].blank?
      # a=user_session[:item_ids].split(','){|x| x.to_i}
      a=user_session[:item_ids]
      b=@clavis_items.collect{|x| x.id}
      @esemplari_non_trovati = (a-b) | (b-a)
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

        heading = params[:heading].blank? ? "Elenco libri a magazzino" : params[:heading]
        @clavis_items.define_singleton_method(:titolo_elenco) do
          heading
        end

        if params[:pdf_template].blank?
          filename="#{@clavis_items.size}_segnaposto.pdf"
          lp=LatexPrint::PDF.new('labels', @clavis_items)
        else
          pdf_template=params[:pdf_template]
          if pdf_template=='topografico'
            # Eventualmente intervenire qui per rimuovere il primo elemento dell'Array
          end
          filename="#{@clavis_items.size}_#{pdf_template}.pdf"
          lp=LatexPrint::PDF.new(pdf_template, @clavis_items, false)
        end
        send_data(lp.makepdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
      format.json { render json: @clavis_items }
    end
  end

  def find_by_home_library_id_and_manifestation_ids
    headers['Access-Control-Allow-Origin'] = "*"
    library_id=params[:library_id].to_i
    manifestation_ids = params[:manifestation_ids].split
    @records = ClavisItem.find_by_home_library_id_and_manifestation_ids(library_id,manifestation_ids)
    respond_to do |format|
      format.html
      format.json { render :json => @records }
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
    render nothing: true, status: 404 and return if !ClavisItem.exists?(params[:id])
    @clavis_item=ClavisItem.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def sync
    # Da rivedere (agosto 2017)
    @clavis_item=ClavisItem.new(params[:i])
    @clavis_item.id=params[:id]
    @clavis_item.opac_visible = params[:i][:opac_visible] == 'true' ? 1 : 0
    new_collocation=@clavis_item.collocation
    if ClavisItem.exists?(params[:id])
      @c_item=ClavisItem.find(params[:id])
      @c_item.title=@clavis_item.title
      @c_item.item_status=ClavisItem.label_to_key(@clavis_item.item_status,'ITEMSTATUS')
      @c_item.loan_status=ClavisItem.label_to_key(@clavis_item.loan_status,'LOANSTATUS')
      @c_item.item_media=ClavisItem.label_to_key(@clavis_item.item_media,'ITEMMEDIATYPE')
      @c_item.section=ClavisItem.section_label_to_key(@clavis_item.section,@clavis_item.owner_library_id)
      @c_item.collocation=new_collocation
      @c_item.opac_visible=@clavis_item.opac_visible
      @c_item.rfid_code=@clavis_item.rfid_code
      @c_item.custom_field1=@clavis_item.custom_field1
      @c_item.custom_field3=@clavis_item.custom_field3
      @c_item.date_updated=@clavis_item.date_updated
      ['owner_library_id','home_library_id','actual_library_id'].each do |f|
        @c_item[f] = @clavis_item.send(f) 
      end
      @c_item.sanifica_collocazione
      @c_item.save if @c_item.changed?
    else
      @clavis_item.loan_status=ClavisItem.label_to_key(@clavis_item.loan_status,'LOANSTATUS')
      @clavis_item.item_media=ClavisItem.label_to_key(@clavis_item.item_media,'ITEMMEDIATYPE')
      @clavis_item.item_status=ClavisItem.label_to_key(@clavis_item.item_status,'ITEMSTATUS')
      @clavis_item.section=ClavisItem.section_label_to_key(@clavis_item.section,@clavis_item.owner_library_id)
      @clavis_item.item_icon=''
      @clavis_item.issue_number=0
      @clavis_item.section=@clavis_item.section.split.first if !@clavis_item.section.nil?
      @clavis_item.save
      # render :template=>"/clavis_items/show" and return
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
    headers['Access-Control-Allow-Origin'] = "https://bct.comperio.it"

    # Vero if da usare: if params[:dng_user].blank?
    # Per debug uso utente sebastiano:
    if params[:dng_user].blank?
      logger.warn("#{Time.now} CSIRTEST: errore, utente_blank ")
      fd=File.open("/home/seb/clavisbct_temp_debug.txt", 'a')
      fd.write("#{Time.now} CSIRTEST: ERRORE: chiamata a closed_stack_item_request con params[:dng_user] BLANK\n")
      fd.close
      render json:{status:'error', requests:ClosedStackItemRequest.count, msg:'Richiesta non registrata<br/>(dng_user mancante)', collocazione:params[:collocazione]}
      return
    end
    # respond_to do |format|
    #   format.json {
    #     logger.warn("#{Time.now} CSIRTEST: format #{format.inspect}")
    #     render json:{status:'ok', requests:ClosedStackItemRequest.count, msg:'Richiesta recepita'}
    #   }
    # end
    # return
    logger.warn("#{Time.now} CSIRTEST: entrato #{params[:dng_user]}")
    cm=ClavisManifestation.find(params[:manifestation_id])
    logger.warn("#{Time.now} CSIRTEST: manifestation_id => #{cm.id}")
    patron=ClavisPatron.find_by_opac_username(params[:dng_user].downcase)
    logger.warn("#{Time.now} CSIRTEST: patron_id => #{patron.id}")
    dng_session=DngSession.find_by_params_and_request(params,request)
    if dng_session.nil?
      fd=File.open("/home/seb/utenti_senza_dng_session.log", 'a')
      fd.write("#{Time.now} patron_id => #{patron.id}\n")
      fd.close
      render json:{status:'error', requests:ClosedStackItemRequest.count, msg:'Non siamo riusciti a registrare la richiesta a causa di un problema tecnico alla cui soluzione stiamo lavorando, ci scusiamo per il disagio', collocazione:params[:collocazione]}
      return
    end
    logger.warn("#{Time.now} CSIRTEST: dng_session_id => #{dng_session.inspect}")
    library_id=params[:library_id]
    logger.warn("#{Time.now} CSIRTEST: inventario => #{params[:inventario]}")
    s,i=params[:inventario].split('-')
    if i.blank?
      collocazione=params[:collocazione].gsub(' ', '.')
      logger.warn("#{Time.now} CSIRTEST: richiesta_a_magazzino senza inventario, collocazione: #{collocazione}")
      sql=%Q{SELECT ci.* FROM clavis.collocazioni cc JOIN clavis.item ci USING(item_id)
                       WHERE cc.collocazione=#{ClavisItem.connection.quote(collocazione)}}
      begin
        item=ClavisItem.find_by_sql(sql).first
      rescue
        logger.warn("#{Time.now} CSIRTEST: errore:")
      end
    else
      item=ClavisItem.find_by_home_library_id_and_inventory_serie_id_and_inventory_number(library_id,s,i)
    end
    logger.warn("#{Time.now} CSIRTEST: step1 => patron con id #{patron.id} richiede item #{item.id}")
    if patron.closed_stack_item_requests.collect {|r| r.item_id}.include?(item.id)
      logger.warn("#{Time.now} CSIRTEST: step2 - richiesta già presente")
      render json:{status:'ok', msg:"Richiesta già presente", collocazione:params[:collocazione]}
    else
      logger.warn("#{Time.now} CSIRTEST: richiesta_a_magazzino #{cm.title}")
      logger.warn("#{Time.now} CSIRTEST: richiesta_a_magazzino #{patron.lastname}")
      logger.warn("#{Time.now} CSIRTEST: richiesta_a_magazzino #{patron.opac_username}")
      logger.warn("#{Time.now} CSIRTEST: richiesta_a_magazzino #{dng_session.inspect}")
      logger.warn("#{Time.now} CSIRTEST: richiesta_a_magazzino #{item.id}")
      logger.warn("#{Time.now} CSIRTEST: richiesta_a_magazzino #{item.title}")
      begin
        logger.warn("#{Time.now} CSIRTEST: item.id: #{item.id} - patron_id: #{patron.id}, dng_session.id: #{dng_session.class}")
        ClosedStackItemRequest.create(item_id:item.id,patron_id:patron.id,dng_session_id:dng_session.id,request_time:Time.now)
      rescue
        logger.warn("#{Time.now} CSIRTEST: Errore #{$!}")
      end
      logger.warn("#{Time.now} CSIRTEST: create ok")
      render json:{status:'ok', requests:ClosedStackItemRequest.count, msg:'Richiesta registrata', collocazione:params[:collocazione]}
    end
  end

  def clear_user_data
    user_session[:item_ids]=nil
    redirect_to clavis_items_path
  end

  def fifty_years
    @clavis_items=ClavisItem.fifty_years(params)
  end

  def controllo_valori_inventariali
    @clavis_items=ClavisItem.controllo_valori_inventariali(params)
  end

  def senza_copertina
    # 'j02','g03'
    cond=[]
    cond << "ci.home_library_id=#{params[:home_library_id]}" if !params[:home_library_id].blank?
    cond << "cm.bib_type = #{ClavisItem.connection.quote(params[:bib_type])}" if !params[:bib_type].blank?
    cond = cond==[] ? '' : "AND #{cond.join(' AND ')}"
    @sql=%Q{select distinct cm."EAN", cm."ISBNISSN", cm.manifestation_id,trim(cm.title) as title from clavis.manifestation cm
  join clavis.item ci using(manifestation_id)
   left join clavis.attachment a on(a.object_id=cm.manifestation_id)
       where ci.manifestation_id!=0 AND a.attachment_id is null #{cond}
   order by cm.manifestation_id;}
    @records=ClavisItem.connection.execute(@sql).to_a
  end

  def cerca_fuoricatalogo
    render text:'ok', layout: 'bctsite'
  end

  private
  def read_sql_and(sql_source)
    if /^-f (.*)/ =~ sql_source
      sourcefile = File.join(Rails.root, 'extras/sql/search', $1)
      File.read(sourcefile)
    else
      sql_source
    end
  end
end
