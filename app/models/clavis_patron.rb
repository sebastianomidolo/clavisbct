# -*- coding: utf-8 -*-

include SoapClient

class ClavisPatron < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  devise :database_authenticatable, :rememberable, :encryptable, :encryptor=>:sha1, :stretches=>10

  alias_attribute :encrypted_password, :opac_secret
  # alias_attribute :password_salt, :opac_secret

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :password_confirmation, :remember_me
  # attr_accessible :opac_username, :opac_secret, :lastname, :name
  attr_accessible :access_note,:barcode,:birth_city,:birth_country,:birth_date,:birth_province,:card_code,:card_expire,:citizenship,:civil_status,:created_by,:date_created,:date_updated,:document_emitter,:document_expiry,:document_number,:gender,:lastname,:loan_class,:modified_by,:name,:national_id,:opac_enable,:opac_secret,:opac_username,:patron_id,:patron_status,:preferred_library_id,:privacy_approve,:registration_library_id
  attr_accessible :access_alert,:areas_of_interest,:biography,:check_in,:check_library,:check_out,:custom1,:custom2,:custom3,:document_type,:last_seen,:max_loans,:opac_secret_expire,:patron_note,:rfid_code,:statistic_study,:statistic_work,:surf_enable,:title,:voice_enable,:voice_pin
  
  self.table_name='clavis.patron'
  self.primary_key='patron_id'

  has_many :loans,:class_name=>'ClavisLoan', :foreign_key=>'patron_id'
  has_many :purchase_proposals, :class_name=>'ClavisPurchaseProposal', :foreign_key=>'patron_id'
  has_many :dng_sessions, :foreign_key=>'patron_id'

  # Esempio: '70067cfc7e1429cfd7b710a19519d913027eb7a3','158.102.56.204, 158.102.162.9'
  def register_dng_login(client_ip)
    # return nil if self.opac_secret!=opac_secret
    dng=DngSession.create(:patron_id=>self.id, :client_ip=>client_ip, :login_time=>Time.now)
    dng
    # dng.log_session_id
  end

  def csir_tickets(library_id,archived=false)
    ClosedStackItemRequest.list(self.id,library_id,pending=false,printed=nil,today=true,archived=archived,reprint=nil).collect{|x| x.daily_counter}.uniq.sort
  end

  def appellativo
    s = self.gender=='F' ? 'Gent.ma' : 'Gentile'
    "#{s} #{self.name} #{self.lastname}"
  end

  def lettore
    self.gender=='F' ? 'Lettrice' : 'Lettore'
  end

  def to_label
    "#{self.name} #{self.lastname}"
  end

  def autorizzato_al_servizio_lp
    self.reload
    self.loan_class=='@' ? true : false
  end

  def codice_fiscale
    require 'codice_fiscale'
    begin
      self.birth_province = self.birth_city[0..1] if self.birth_province.blank?
      self.birth_province = self.birth_province[0..1]
      sx = self.gender == 'M' ? :male : :female
      CodiceFiscale.calculate(
        :name          => self.name,
        :surname       => self.lastname,
        :gender        => sx,
        :birthdate     => self.birth_date,
        :province_code => self.birth_province.strip,
        :city_name     => self.birth_city.strip
      )
    rescue
      raise "Errore calcolo CF #{$!}"
    end
  end

  def national_id_check
    begin
      cf=self.codice_fiscale
    rescue
      puts "Errore su patron #{self.barcode}: #{$!}"
      return false
    end
    if self.national_id.upcase===cf
      true
    else
      "dovrebbe essere #{cf} invece risulta come #{self.national_id}"
    end
  end

  def autorizzato_download_pdf(clavis_manifestation)
    # Esempio su manifestation 571777 e uid 52697 cioè:
    # reload!;ClavisPatron.find(52697).autorizzato_download_pdf(ClavisManifestation.find(571777))
    # Esempio di pdf libero (in quanto composto da oggetti a loro volta liberi):
    # reload!;ClavisPatron.find(8959).autorizzato_download_pdf(ClavisManifestation.find(219606))
    aut=true
    scadenza=nil
    return false if clavis_manifestation.d_objects.size==0
    dob=clavis_manifestation.d_objects.first
    dirname=File.dirname(dob.filename)
    clavis_manifestation.d_objects.each do |o|
      # Provvisorio: solo i files in doc_delivery sono autorizzabili, gli altri no in ogni caso (per ora)
      if !(/^doc/ =~  o.filename)
        puts "filename #{o.filename}"
        aut=false
      end
      next if o.access_right_id==0
      return false if o.access_right_id==2
      return false if o.access_right_id==1
      mid=o.xmltag(:mid).to_i
      if mid==0
        # puts o.filename
      end
      next if mid!=clavis_manifestation.id
      sc = o.xmltag(:sc)
      next if sc.blank?
      uid=o.xmltag(:uid).to_i
      puts "uid: #{uid}"
      # uid=8959; # debug only
      if uid!=self.id and uid!=0
        aut=false
        # <sc>mm12</sc>
        mesi = sc.gsub('mm','').split[0].to_i
        # puts "mesi: #{mesi}"
        # o.tags="<r><dc>2012-08</dc></r>"
        dc = o.xmltag(:dc)
        if dc.blank?
          dc = o.f_mtime
        else
          dc_anno,dc_mese=dc.split('-')
          # puts dc_anno
          # puts dc_mese
          dc = Time.new(dc_anno, dc_mese)
        end
        # puts "data_caricamento_file: #{dc}"
        t1 = dc + mesi.months
        # puts t1
        scadenza = t1 if scadenza.nil? or scadenza > t1
      end
    end
    return false if scadenza.nil? and aut==false
    # puts "scadenza: #{scadenza}"
    if scadenza.nil?
      # In realtà è un po' troppo permissivo: potrebbero esserci e ci sono casi
      # in cui il semplice fatto che non sia indicata una scadenza dei diritti
      # non implica che i diritti ci siano
      true
    else
      Time.now >= scadenza
    end
  end

  def closed_stack_item_requests_by_session
    time_limit = "request_time-now() > interval '600 minutes ago'"
    ActiveRecord::Base.connection.execute("SET timezone to 'UTC'")
    sql=%Q{SELECT DISTINCT ir.* FROM closed_stack_item_requests ir
        JOIN dng_sessions s ON(ir.dng_session_id=s.id)
              WHERE #{time_limit} ORDER BY request_time;}
    puts sql
    ClosedStackItemRequest.find_by_sql(sql)
  end
  def closed_stack_item_requests(library_id)
    ClosedStackItemRequest.list(self.patron_id,library_id,nil,nil,true,false,nil,'request_time ASC')
  end

  def closed_stack_item_request_pdf(dng_session)
    inputdata=[]
    inputdata << self
    inputdata << dng_session
    lp=LatexPrint::PDF.new('closed_stack_item_request', inputdata)
    lp.makepdf
  end
  def closed_stack_print_request
    inputdata=[]
    inputdata << self
    lp=LatexPrint::PDF.new('closed_stack_item_request', inputdata, false)
    lp.makepdf
  end

  def find_common_loans_patrons_old
    temptable='temp_commonloans'
    sql = %Q{
create temp table #{temptable} as
 with tt as
 (select patron_id,#{self.id} as target_patron_id,
      array_agg(distinct manifestation_id order by manifestation_id) as manifestations
           from prestiti where patron_id in (select distinct patron_id from prestiti
	            where manifestation_id in (select distinct manifestation_id from prestiti
      where patron_id=#{self.id})) group by patron_id)
    select t1.patron_id,t2.manifestations,array(select unnest(t1.manifestations) intersect select unnest(t2.manifestations))
     as common_manifestations from tt t1 left join tt t2 on(t1.patron_id!=t2.patron_id)
      where t2.patron_id=t1.target_patron_id;
  select array_length(p.manifestations,1) as totale,
  array_to_string(common_manifestations, ', ') as common_manifestations, cp.patron_id,cp.lastname,cp.name,array_length(common_manifestations, 1) as numtit
     from #{temptable} p join clavis.patron cp using(patron_id) order by array_length(common_manifestations, 1) desc limit 20;}
    puts sql
    r=self.connection.execute(sql).to_a
    self.connection.execute("drop table #{temptable}")
    r
  end

  def find_common_loans_patrons
    sql = %Q{ with tt as
    (select t2.patron_id,#{self.id} as target_patron_id,
     array(select unnest(t1.manifestations) intersect select unnest(t2.manifestations))
     as common_manifestations, t1.manifestations, array_length(t1.manifestations,1) as totale
     from patron_manifestations t1 left join patron_manifestations t2
     on(t1.patron_id!=t2.patron_id) where t1.patron_id=#{self.id} and t2.patron_id in
     (select distinct t2.patron_id from prestiti t1, prestiti t2 where t1.manifestation_id=t2.manifestation_id
      and t1.patron_id!=t2.patron_id and t1.patron_id=#{self.id}) limit 2000)
     select tt.*,cp.name,cp.lastname,array_length(common_manifestations, 1) as numtit,
      array_to_string(common_manifestations, ', ') as common_manifestations
  from tt join clavis.patron cp using(patron_id) 
      order by array_length(common_manifestations, 1) desc limit 20;}
    puts sql
    r=self.connection.execute(sql).to_a
    # self.connection.execute("drop table #{temptable}")
    r
  end

  # Conta le proposte di acquisto escluse quelle annullate dall'utente
  # Se "since" è nil, conta le proposte dall'inizio dell'anno corrente,
  # altrimenti le conta dall'intervallo espresso dal parametro since, esempio "1 year", "6 months", "45 days" etc.
  def purchase_proposals_count(since=nil)
    if since.nil?
      y=Time.now.year
      interval = " AND proposal_date >= '#{y}-01-01'"
    else
      interval = " AND proposal_date between now() - interval '#{since}' and now()"
    end
    sql = %Q{select count(*) from clavis.purchase_proposal where patron_id=#{self.id} #{interval} and status IN ('A','B','C','E' );}
    # puts sql
    self.connection.execute(sql).first['count'].to_i
    # self.purchase_proposals.where("status IN ('A','B','C','E' )#{interval}").count
  end

  def sql_for_update_date_updated_field
    %Q{update patron set date_updated =
         (select event_date from changelog where object_class='Patron' and object_id = #{self.id}
           and event_date is not null order by event_date desc limit 1)
         where patron_id=#{self.id};}
    %Q{with t1 as (select object_id as patron_id,event_date as last_updated from changelog where object_class='Patron'
                and object_id = #{self.id} and event_date is not null order by event_date desc limit 1)
           select t1.patron_id,t1.last_updated,p.date_updated from t1 join patron p using(patron_id);}
    %Q{begin;
      with t1 as (select object_id as patron_id,event_date as last_updated from changelog where object_class='Patron'
                  and object_id = #{self.id} and event_date is not null order by event_date desc limit 1)
      update patron inner join t1 ON t1.patron_id=patron.patron_id
      SET patron.date_updated = t1.last_updated
      where t1.last_updated > patron.date_updated;
      select date_updated from patron where patron_id=#{self.id};
      rollback;}
    %Q{begin;
      with t1 as (select object_id as patron_id,event_date as last_updated from changelog where object_class='Patron'
                  and object_id = #{self.id} and event_date is not null order by event_date desc limit 1)
      update patron inner join t1 ON t1.patron_id=patron.patron_id
      SET patron.date_updated = t1.last_updated, patron.modified_by=1
      where t1.last_updated > patron.date_updated;
      select date_updated from patron where patron_id=#{self.id};
rollback;}
  end

  def clavis_url(mode=:view)
    ClavisPatron.clavis_url(self.id,mode)
  end

  def default_password?
    ClavisPatron.mydiscovery_authorized?(self.opac_username,self.birth_date.strftime('%d%m%Y'))
  end

  #  "MDLSST57M08C351P"
  def estrai_dati_da_codice_fiscale
    return {} if self.national_id.nil? or self.national_id.size!=16
    h = Hash.new
    mesi = %w[A B C D E H L M P R S T]

    cf=self.national_id
    puts cf
    h[:year]  = cf[6..7].to_i
    h[:month] = mesi.index(cf[8])+1
    dg = cf[9..10].to_i
    puts dg
    h[:day]   = dg
    if dg > 31
      h[:gender] = 'F'
      h[:day]   = dg - 40
    else
      h[:gender] = 'M'
    end
    sql="SELECT denominazione,vardenom FROM comuni_italiani where codnaz=#{self.connection.quote(cf[11..14])};"
    puts sql
    h[:place] = self.connection.execute(sql).collect {|r| r.inspect}
    h
  end

  def ClavisPatron.clavis_url(id,mode=:view)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    r="#{host}/index.php?page=Circulation.PatronViewPage&id=#{id}" if mode==:view
    r="#{host}/index.php?page=Circulation.NewLoan&patronId=#{id}" if mode==:newloan
    r
  end

  # Sperimentale, 20 agosto 2021 - non ha un reale utilizzo, per ora
  def soap_get_loans
    client = SoapClient::get_wsdl('loan')
    soap = :get_patron_active_loans
    r = client.call(soap, message: {username:self.opac_username})
    return [] if r.body["#{soap}_response".to_sym][:return].nil?
    res=r.body["#{soap}_response".to_sym][:return][:item]
    return if res.nil?
    res.each do |e|
      if e.class == Array
        next if e.first != :item
        e[1].each do |i|
          next if !['ManifestationId','Title','ItemId'].include?(i[:key])
          puts "A: #{i.inspect}"
        end
      else
        e[:item].each do |i|
          next if !['ManifestationId','Title','ItemId'].include?(i[:key])
          puts "B: #{i.inspect}"
        end
      end
    end
    "test"
  end

  def ClavisPatron.insert_or_update_patron(soap_response)
    # puts "Inserisco o aggiorno utente da risposta ottenuta da chiamata soap - #{soap_response.class}"
    h = Hash.new
    soap_response.each do |e|
      next if e.class!=Hash
      s = e[:key]
      h[s] = {}
      e.each do |a|
        next if a[1] == s
        h[s]=a
      end
    end
    attrib={}
    h['patron'][1][:item].each do |e|
      fld=e[:key].underscore
      val=e[:value]
      next if val.blank? or val.class==Hash
      # puts "#{e.inspect} - val class : #{val.class}"
      attrib[fld]=val
    end
    # n => new patron
    # o => old patron, se esiste
    n=self.new(attrib)
    if self.exists?(n)
      o=self.find(n)
      if n.attributes != o.attributes
        o.update_attributes(n.attributes)
        o.save
      end
      o
    else
      n.save
      n
    end
  end

  def cancellami_se_non_esisto_in_clavis
    if ClavisPatron.mydiscovery_user(self.id)
      puts "patron_id #{self.id} trovato in Clavis"
      self
    else
      puts "patron_id #{self.id} NON trovato in Clavis, lo cancello"
      self.destroy
      nil
    end
  end

  def allinea_da_clavis
    soap_response=ClavisPatron.mydiscovery_user(self.id)
    ClavisPatron.insert_or_update_patron(soap_response)
  end

  def ClavisPatron.mydiscovery_authorized?(username,password)
    client = SoapClient::get_wsdl('user')
    r = client.call(:login_user, message: {username:username,password:password})
    r.body[:login_user_response][:return]
  end

  def ClavisPatron.mydiscovery_user(username,searchfield=nil)
    if searchfield.nil?
      searchfield=username.class == Fixnum ? 'id' : 'username'
    end
    client = SoapClient::get_wsdl('user')
    r = client.call(:get_user_data, message: {search:username,searchfield:searchfield})
    return nil if r.body[:get_user_data_response][:return].nil?
    r.body[:get_user_data_response][:return][:item]
  end

  def ClavisPatron.allinea_da_clavis
    puts "patron last id: #{self.last.id}"
    cnt = 0
    while true
      cnt += 1
      u=self.mydiscovery_user(self.last.id + 1)
      break if u.nil?
      if cnt > 10
        puts "ClavisPatron.allinea_da_clavis dice: superato il contatore degli allineamenti da ClavisPatron: #{cnt}"
        break
      end
      p=self.insert_or_update_patron(u)
      puts "inserito #{p.id} - #{p.to_label}"
    end
  end

  def ClavisPatron.find_duplicates(params)
    if params[:library_id]=='-1'
      cond = ''
    else
      cond = params[:library_id].blank? ? 'where false' : "WHERE split_part(libraries, ',', 2)::integer=#{params[:library_id].to_i}"
    end

    sql=%Q{with t1 as
(
select upper(p.lastname) as lastname,upper(p.name) as name,upper(p.birth_city) as birth_city,birth_date,
             array_to_string(array_agg(p.patron_id order by p.date_created),',') as patron_ids,
	     array_to_string(array_agg(p.date_created order by p.date_created),',') as creation_dates,
             array_to_string(array_agg(p.created_by order by p.date_created),',') as creators,
             array_to_string(array_agg(cl.username order by p.date_created),',') as creators_usernames,
             array_to_string(array_agg(p.barcode order by p.date_created), ',') as barcodes,
             array_to_string(array_agg(p.registration_library_id order by p.date_created), ',') as libraries,
             array_to_string(array_agg(p.opac_username order by p.date_created), ',') as opac_usernames,count(*)
            from clavis.patron p join clavis.librarian cl on (cl.librarian_id=p.created_by)
	    group by p.lastname,p.name,p.birth_city,p.birth_date  having count(*) > 1
)
select t1.lastname,t1.patron_ids,
  split_part(patron_ids, ',', 1)::integer as primo_iscritto_id,
  split_part(patron_ids, ',', 2)::integer as ultimo_iscritto_id,
  split_part(creation_dates, ',', 1)::timestamp as primo_data_iscrizione,
  split_part(creation_dates, ',', 2)::timestamp as ultimo_data_iscrizione,
  split_part(creators_usernames, ',', 1) as primo_iscrivente,
  split_part(creators_usernames, ',', 2) as ultimo_iscrivente,
  split_part(opac_usernames, ',', 1) as primo_username,	
  split_part(opac_usernames, ',', 2) as ultimo_username,
  split_part(libraries, ',', 1) as primo_library,	
  split_part(libraries, ',', 2) as ultimo_library,
  split_part(barcodes, ',', 1) as primo_barcode,
  case when split_part(barcodes, ',', 2) = '' then 'missing barcode' else split_part(barcodes, ',', 2) end as ultimo_barcode 
 from t1 #{cond} order by ultimo_data_iscrizione desc}

         fd = File.open("/home/seb/utenti_duplicati.sql", "w")
         fd.write(sql)
         fd.close

    self.paginate_by_sql(sql, per_page:50, page:params[:page])
  end

  def ClavisPatron.notifiche_pronti_al_prestito_non_confermate(library_ids,params)
    intervallo = params[:interval].blank? ? '1 week' : params[:interval]
    cond = []
    if (intervallo =~ /^from (.*)/) == 0
      cond << "a.action_date >= #{ClavisPatron.connection.quote($1)} "
    else
      cond << "a.action_date > now() - interval '#{intervallo}'"
    end

    if library_ids.size > 0 
      cond << "a.library_id in (#{library_ids.join(',')})"
      cond << "a.library_id = #{params[:library_id].to_i}" if !params[:library_id].blank?
    else
      cond << "false"
    end
    cond = cond.join(' AND ')
    sql = %Q{select n.n_state as state,
       array_to_string(array_agg(ct.contact_type order by ct.contact_id), ',') as contact_types,
       array_to_string(array_agg(ct.contact_pref order by ct.contact_id), ',') as contact_prefs,	
    case when x.last_state is null then 'Nessuna notifica inviata' else x.last_state end as last_state,
n.n_channel,n.notification_channel,x.notes,a.item_id,
 substr(ci.title,1,30) as item_title,a.action_date,
 x.last_channel,n.object_id as patron_id,cp.barcode,n.delivery_date,
    n.notification_id,x.notification_id as last_notification_id,
    a.library_id as action_library_id

FROM clavis.last_item_actions a
   left join clavis.view_notifications n
     on (n.object_id=a.patron_id and n.notification_class='F' and n.date_created >= a.action_date
        and n.notification_state != 'C')

  LEFT JOIN LATERAL (
    select 
--    case when n_state is null then 'Non presente' else n_state end as last_state,
      n_state as last_state,
      case when notification_state != 'C' then notes else '' end as notes,
notification_id,notification_state,n_channel as last_channel from clavis.view_notifications
       where object_id=n.object_id
        and date_created>n.date_created
        and notification_class='F'
	order by notification_id limit 1
  ) as x on true
  join clavis.patron cp on(cp.patron_id=n.object_id)
  left join clavis.contact ct on(ct.patron_id=cp.patron_id)
  join clavis.item ci on(ci.item_id=a.item_id)

 where 
 ci.loan_status='F' and
a.action_type='I' and a.patron_id is not null
   and (x is null or x.last_state!='C')
   and #{cond}
   group by state,x.last_state,n.n_channel,n.notification_channel,x.notes,a.item_id,
   ci.title,a.action_date,x.last_channel,n.object_id,cp.barcode,n.delivery_date,n.notification_id,x.notification_id,
   cp.patron_id,action_library_id
-- order by cp.patron_id,n.notification_id
order by action_library_id,cp.patron_id,n.notification_id}
    # puts sql
    #fd = File.open("/home/seb/notifiche_non_confermate.sql", "w")
    #fd.write(sql)
    #fd.close
    self.connection.execute(sql).to_a
  end

  
  def ClavisPatron.sql_per_schiacciamento(new,old)
    #sql = %Q{BEGIN;UPDATE patron set opac_secret = (select opac_secret   from patron where patron_id=#{new}),
    #          opac_username = (select opac_username from patron where patron_id=#{new})
    #   WHERE patron_id=#{old};ROLLBACK;}
    sql = %Q{BEGIN;
UPDATE patron
 set opac_secret = (select opac_secret   from (select opac_secret   from patron where patron_id=#{new}) t1),
   opac_username = (select opac_username from (select opac_username from patron where patron_id=#{new}) t2)
  WHERE patron_id=#{old};
ROLLBACK; -- Vedi dettagli qui: https://dev.mysql.com/doc/refman/8.0/en/update.html}
    #puts "vecchio: #{old}"
    #puts "nuovo: #{new}"
    sql
  end

end
