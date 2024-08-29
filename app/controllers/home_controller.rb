# coding: utf-8
class HomeController < ApplicationController
  layout 'navbar'
  # before_filter :authenticate_user!, only: 'bidcr'


  # before_filter :authenticate_user!
  def index
    @pagetitle="ClavisBCT"
    @msg=Time.now


    # authenticate_user!

    if !current_user.nil?
      if SbctTitle.user_roles(current_user).include?('AcquisitionSupplier')
        redirect_to sbct_invoices_path
      end
      user_session[:current_order]=nil
      # user_session[:current_budget]=nil
      user_session[:events_mode]=nil
      # user_session[:current_list]=nil
    end
    
    if !current_user.nil? and ['dorcol'].include?(current_user.email)
      fd=File.open(File.join(Rails.root.to_s, 'tmp', 'my_ip.txt'), 'w')
      fd.write "# dorcol ip:\nsshd: #{request.remote_addr}\n"
      fd.close
    end
    if !current_user.nil? and current_user.email=='sebix'
      fd=File.open(File.join(Rails.root.to_s, 'tmp', 'sebix_ip.txt'), 'w')
      fd.write "# sebix ip:\nsshd: #{request.remote_addr}\n"
      fd.close
    end

  end

  def jsonip
    headers['Access-Control-Allow-Origin'] = "*"
    headers['Access-Control-Allow-Methods'] = "GET"
    render json: {ip: DngSession.format_client_ip(request)}.to_json
  end

  def logxhr
    headers['Access-Control-Allow-Origin'] = "http://bctwww.comperio.it"
    # headers['Access-Control-Allow-Methods'] = "POST"
    # headers['Access-Control-Allow-Credentials'] = true
    # headers['Access-Control-Allow-Headers'] = 'Content-Type'

    ip=DngSession.format_client_ip(request)
    res = [ip:ip, datetime: Time.now, target: params[:target], query_string: params[:qs]]
    XhrRequest.create(target:params[:target],timestamp:Time.now,ip:ip,qs:params[:qs])
    render text: res.to_s
  end

  def test
    render :text=>File.read('/home/storage/preesistente/static/changelog_test.html'), :layout=>true
  end

  def checkdewey
    @sql=%Q{select home_library_id,item_id,manifestation_id,manifestation_dewey,section,
           collocation, cl.shortlabel,trim(ci.title) as title
  from clavis.item ci join clavis.library cl on (cl.library_id=ci.home_library_id)
 where manifestation_id>0 and manifestation_dewey != '' and
     home_library_id not in (2,3,31,32,677,803) and item_media='F' and section = 'BCT'
      and item_status!='E' and custom_field3!='Allineamento provvisorio ClavisBCT' and ci.collocation!=''
     and regexp_replace(trim(collocation),'^((C|P|R|V|VP|RC|PC)(.| ))','') NOT LIKE substr(manifestation_dewey,1,3) || '%'
     order by collocation}
    @records=ActiveRecord::Base.connection.execute(@sql)
  end

  def bidcr
    u=ActiveRecord::Base.connection.quote(params[:user])
    d=params[:days].to_i
    bid_source = params[:bid_source].blank? ? '' : " AND bid_source='#{params[:bid_source]}'"
    sql=%Q{select title,bid,bid_source,date_created,date_updated from clavis.manifestation where created_by = #{u} and date_created>now()-interval '#{d} days' #{bid_source} order by date_created}
    @records=ActiveRecord::Base.connection.execute(sql).to_a
    sql=%Q{select date_trunc('hour',date_created) as date_created,count(*) from clavis.manifestation where created_by = #{u} and date_created>now()-interval '#{d} days' group by date_trunc('hour',date_created) order by date_created}
    @sommario=ActiveRecord::Base.connection.execute(sql).to_a
  end

  def senzapiano
    sql="select item_id from clavis.centrale_locations where piano is null limit 10"
    ids=ActiveRecord::Base.connection.execute(sql).to_a.collect {|i| i['item_id']}
    redirect_to clavis_items_path(item_ids:ids.join('+'))
  end
  
  def spazioragazzi
    render :text=>File.read('/tmp/indexfile.html')
  end

  def senzasoggetto
    sql=%Q{
with manifestations as (
select distinct cm.manifestation_id,cm.bib_level,cm.bib_type,cm.created_by,ci.item_id,
  ci.inventory_serie_id
 from clavis.manifestation cm
 join clavis.item ci using(manifestation_id)
left join
 clavis.l_authority_manifestation am using(manifestation_id) left join
 clavis.authority ca using(authority_id) where am.link_type isnull
 and ci.home_library_id=2
)
select cm.* from manifestations cm left join
  clavis.l_manifestation lm on(cm.manifestation_id in(manifestation_id_up,manifestation_id_down))
  where cm.bib_level='m' and cm.bib_type='a01' and lm is null
  and cm.inventory_serie_id not in ('CLA','TAT') and cm.created_by=1;
}
    ids=ActiveRecord::Base.connection.execute(sql).to_a.collect {|i| i['item_id']}
    user_session[:item_ids]=nil
    redirect_to clavis_items_path(item_ids:ids.join(' '),sql:sql,per_page:9999)
  end
  
  def uni856
    @pagetitle='Titoli in Clavis con URL (unimarc tag 856)'
    @clavis_manifestation = ClavisManifestation.new(params[:clavis_manifestation])
    filter = params[:librarian_id].blank? ? '' : "#{params[:librarian_id]} IN (cm.modified_by, cm.created_by)"
    conn = ActiveRecord::Base.connection
    cond = []
    cond << filter if !filter.blank?
    if !@clavis_manifestation.title.blank?
      ts=conn.quote_string(textsearch_sanitize(@clavis_manifestation.title))
      cond << "(to_tsvector('simple', cm.title) @@ to_tsquery('simple', '#{ts}') OR u.nota ~* #{conn.quote(@clavis_manifestation.title)})"
    end
    cond << "cm.bid ~* #{conn.quote(@clavis_manifestation.bid)}" if !@clavis_manifestation.bid.blank?
    cond << "cm.bib_level = #{conn.quote(@clavis_manifestation.bib_level)}" if !@clavis_manifestation.bib_level.blank?
    cond = cond==[] ? '' : "WHERE #{cond.join(' AND ')}"
    sql=%Q{select trim(cm.title) as title,u.*,cm.created_by || ',' || cm.modified_by as librarian_id, cm.bid from clavis.uni856 u
        join clavis.manifestation cm using(manifestation_id) #{cond}
         order by lower(u.nota),cm.sort_text}
    @records=ActiveRecord::Base.connection.execute(sql)
  end

  def url_sbn
    @pagetitle='Titoli in Clavis con URL (unimarc tag 856 e 300)'
    @clavis_manifestation = ClavisManifestation.new(params[:clavis_manifestation])
    filter = params[:librarian_id].blank? ? '' : "#{params[:librarian_id]} IN (cm.modified_by, cm.created_by)"
    conn = ActiveRecord::Base.connection
    cond = []
    cond << filter if !filter.blank?
    if !@clavis_manifestation.title.blank?
      ts=conn.quote_string(textsearch_sanitize(@clavis_manifestation.title))
      cond << "(to_tsvector('simple', cm.title) @@ to_tsquery('simple', '#{ts}') OR u.nota ~* #{conn.quote(@clavis_manifestation.title)})"
    end
    cond << "cm.bid ~* #{conn.quote(@clavis_manifestation.bid)}" if !@clavis_manifestation.bid.blank?
    cond << "cm.bib_level = #{conn.quote(@clavis_manifestation.bib_level)}" if !@clavis_manifestation.bib_level.blank?
    cond << "u.unimarc_tag = #{conn.quote(params[:unimarc_tag])}" if !params[:unimarc_tag].blank?
    cond = cond==[] ? '' : "AND #{cond.join(' AND ')}"
    sql=%Q{select trim(cm.title) as title,u.*,cm.created_by || ',' || cm.modified_by as librarian_id, cm.bid from clavis.url_sbn u
        join clavis.manifestation cm using(manifestation_id) WHERE u.url is not null #{cond}
         order by trim(lower(cm.title)),lower(u.nota)}
    @records=ActiveRecord::Base.connection.execute(sql)
  end

  def dup_barcodes
    @pagetitle='Esemplari con barcodes duplicati'
    @records=ClavisItem.dup_barcodes
  end

  def esemplari_con_rfid
    if params[:library_id].blank?
      @pagetitle='Esemplari con tag RFID'
      @records=ClavisItem.lista_esemplari_con_tag_rfid(params[:library_ids])
    else
      @library=ClavisLibrary.find(params[:library_id])
      @ancora_da_taggare=ClavisItem.conta_esemplari_senza_tag_rfid(@library.id)
      cond=params[:datefrom].blank? ? '' : "AND snapshot_date >= '#{params[:datefrom]}'"
      @records=ActiveRecord::Base::connection.execute("select snapshot_date,tagged_count from rfid_summary where library_id = #{@library.id} #{cond} order by snapshot_date")
      @pagetitle="Esemplari con tag RFID - Biblioteca #{@library.shortlabel.strip}"
    end
    respond_to do |format|
      format.html {}
      format.csv {}
    end
  end

  def iccu_link
    if !params[:bid].blank?
      @url=ClavisManifestation.new(bid_source: 'SBN', bid: params[:bid]).iccu_opac_url
    end
  end

  def confronto_consistenze_esemplari
  end

  def controllo_provincia
    conn=ActiveRecord::Base.connection
    @sql=%Q{select * from comuni_italiani where denominazione ~* #{conn.quote(params[:city])} }
    @records=conn.execute(@sql)
    @provs=[]
    @prov_ok=false
    @records.each do |r|
      @provs << r['provincia']
    end
    @prov_ok = true if @provs.include?(params[:province])
    if !params[:patron_id].blank?
      @patron = ClavisPatron.find(params[:patron_id])
      @cf_suggest=true
      begin
        cf=@patron.codice_fiscale
        if @patron.national_id!=cf
          @cf="CF calcolato: #{@patron.codice_fiscale}"
          @patron.national_id=@patron.codice_fiscale
          @patron.save if @patron.changed?
        else
          @cf="CF presente: #{@patron.codice_fiscale}"
          # @cf_suggest=false
        end
      rescue
        @cf="Errore: #{$!}"
      end
      if @patron.birth_city!=params[:city]
        @patron.birth_city=params[:city].strip
        @patron.save
      end
    end
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def getpdf
    pdf_file = ClavisManifestation.free_pdf_filename(params[:manifestation_id])
    if File.readable?(pdf_file)
      cm=ClavisManifestation.find(params[:manifestation_id])
      filename="#{cm.title.strip}.pdf"
      response.headers['Content-Length'] = File.size(pdf_file)
      send_file(pdf_file, filename:filename, type:'application/pdf', disposition:'inline')
    else
      render text:"non esiste: #{pdf_file}"
    end
  end

end
