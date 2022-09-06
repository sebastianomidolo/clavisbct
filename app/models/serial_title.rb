# coding: utf-8
class SerialTitle < ActiveRecord::Base
  attr_accessible :title, :manifestation_id, :sortkey, :estero, :sospeso, :updated_by, :prezzo_stimato, :note, :note_fornitore, :serial_list_id

  belongs_to :serial_list
  belongs_to :serial_invoice

  has_many :serial_subscriptions

  # validates :title, presence: true
  validates_uniqueness_of :title, scope: :serial_list_id

  before_save :set_date_updated

  def prezzo_stimato_per_numero_copie
    self.prezzo_stimato
  end

  def clavis_manifestation
    self.manifestation_id.nil? ? nil : ClavisManifestation.find(self.manifestation_id)
  end

  def get_manifestation_id
    return self.manifestation_id if !self.manifestation_id.nil?
    bid=self.get_field('BID: ').first
    return nil if bid.nil? or bid.size!=10
    cm=ClavisManifestation.find_by_bid(bid)
    return nil if cm.nil?
    self.manifestation_id=cm.id
    self.save
    self.manifestation_id
  end

  def set_date_updated
    if self.title.blank?
      if (cm = self.clavis_manifestation)
        self.title = self.clavis_manifestation.title
        self.sortkey = self.clavis_manifestation.sort_text
      else
        self.title = 'Nuovo titolo'
      end
    end
    self.date_updated=Time.now
    self.sortkey = self.title.downcase if self.sortkey.blank?
  end

  def clavis_libraries(all=false,user=nil)
    if all and !user.nil?
      # user=User.find(21)
      user_join = user.nil? ? '' : "LEFT JOIN clavis.l_library_librarian ll on(ll.library_id = l.library_id AND ll.librarian_id=#{user.clavis_librarian.id})"
      sql = %Q{SELECT l.*,l.library_id as ok_library_id,p.*,ll.librarian_id as okgest
              FROM clavis.library l LEFT JOIN #{SerialSubscription.table_name} p on(p.library_id=l.library_id and p.serial_title_id=#{self.id})
               #{user_join}
              WHERE l.library_internal='1' and l.library_code!='SBCT' order by p.serial_title_id,ll.library_id,p.library_id,l.label;}

      # Nuova versione che usa serial_libraries
      sql = %Q{SELECT cl.label, l.*,l.clavis_library_id as ok_library_id,s.*,ll.librarian_id as okgest,
               st.prezzo_stimato, s.numero_copie
              FROM serial_libraries l LEFT JOIN #{SerialSubscription.table_name} s
                 ON(s.library_id=l.clavis_library_id and s.serial_title_id=#{self.id})
             LEFT JOIN clavis.l_library_librarian ll 
                 ON(ll.library_id = l.clavis_library_id AND ll.librarian_id=#{user.clavis_librarian.id})
             LEFT JOIN clavis.library cl ON(cl.library_id=l.clavis_library_id)
 	     LEFT JOIN serial_titles st ON(st.serial_list_id=l.serial_list_id and st.id=s.serial_title_id)
             WHERE l.serial_list_id=#{self.serial_list.id}
              ORDER BY s.serial_title_id,ll.library_id,s.library_id,l.nickname;}
      
    else
      sql = "SELECT * from #{SerialSubscription.table_name} p join clavis.library l using(library_id) where p.serial_title_id=#{self.id} order by l.label"
    end

    fd=File.open("/home/seb/serial_title_trova.sql", "w")
    fd.write(sql)
    fd.close

    puts sql
    ClavisLibrary.find_by_sql(sql)
  end
  
  def get_field(label)
    return [] if self.textdata.nil?
    res=[]
    x=Regexp.new("^#{label}(.*)")
    self.textdata.each_line do |l|
      res << $1.strip if l =~ x
    end
    res
  end

  def aggiorna_sospeso
    f=self.get_field('TI_ ').first
    return nil if f.nil?
    self.sospeso = (f =~ /cessata|sospesa/).nil? ? false : true
    self.save!
  end

  def aggiorna_estero
    return if !self.estero.nil?
    puts "aggiorno estero #{self.id} - #{self.title}"
    f=self.get_field('ST: ').first
    if f.nil?
      self.estero = true
    else
      self.estero = (f =~ /IT/).nil? ? true : false
    end
    self.save! if self.changed?
  end

  def aggiorna_serial_subscriptions(siglebib={})
    siglebib=SerialTitle.siglebib if siglebib=={}
    sql=[]
    self.get_field('B: ').each do |b|
      # puts "B: #{b}"
      sigla,forn,nota=b.split
      next if forn.blank?
      library_id=siglebib[sigla.to_sym]
      next if library_id.nil?
      puts "sigla: #{sigla} => #{library_id}"
      sql << "INSERT INTO #{SerialSubscription.table_name}(serial_title_id,library_id,note,tipo_fornitura) values (#{self.id},#{library_id},#{self.connection.quote(nota)},#{self.connection.quote(forn[1])});\n"
      # puts "forn: #{forn}"
      # puts "nota: #{nota}"
    end
    return if sql==[]
    self.connection.execute(sql.join)
  end

  def SerialTitle.trova(params={},invoice_filter_enabled=false)
    cond = Array.new
    with_cond = Array.new
    cond << "sospeso=#{self.connection.quote(params[:sospeso])}" if !params[:sospeso].blank?
    cond << "estero=#{self.connection.quote(params[:estero])}" if !params[:estero].blank?

    if params[:library_id].to_i==-1
      cond = cond==[] ? '' : " AND #{cond.join(' AND ')}"
      sql=%Q{select st.title,st.id,st.prezzo_stimato,st.prezzo_stimato as prezzo_totale_stimato,st.note,st.note_fornitore,
        '[vai a acquisizioni]' as library_names,0 as tot_copie, 0 as numero_copie, '' as issue_arrival_date,
             '' as frequency_label, null as manifestation_id, '' as publisher, '' as invoice_ids
           from #{SerialTitle.table_name} st left join #{SerialSubscription.table_name} ss
                  on(st.id=ss.serial_title_id) where st.serial_list_id=#{params[:serial_list_id]}
           and ss is null #{cond} order by st.sortkey, lower(st.title);}
    else
      if !params[:library_id].blank?
        library_id=params[:library_id].to_i
        with_cond << "library_id=#{library_id}"
      end
      if params[:items_details]=='t'
        array_order='issue_year desc, issue_number desc'
        issues_join = %Q{left join lateral
 (

select i.manifestation_id,i.item_id,i.issue_year,i.issue_number,
   to_char(issue_arrival_date, 'dd-mm-yyyy') as issue_arrival_date,
   to_char(issue_arrival_date_expected, 'dd-mm-yyyy') as issue_arrival_date_expected,
   i.issue_description,
   i.issue_status as issue_status_label
     from clavis.item i
   where i.manifestation_id=st.manifestation_id AND home_library_id=#{library_id}
    and i.issue_year is not null
     order by i.issue_year desc, i.issue_number desc
    limit 6

) as i on i.manifestation_id=cm.manifestation_id}
        issues_select = %Q{,\n
             array_agg(i.item_id order by #{array_order}) as item_ids,
             array_agg(i.issue_arrival_date order by #{array_order}) as issue_arrival_dates,
             array_agg(i.issue_arrival_date_expected order by #{array_order}) as issue_arrival_dates_expected,
	     array_agg(i.issue_description order by #{array_order}) as issue_descriptions,
	     array_agg(issue_status_label order by #{array_order}) as issue_status}
      else
        issues_join = ''
        issues_select = ''
      end
      with_cond << "tipo_fornitura=#{self.connection.quote(params[:tipo_fornitura])}" if !params[:tipo_fornitura].blank?
      # with_cond << "s.serial_invoice_id is null" if !params[:invoice_id].blank?
      cond << "serial_frequency_of_issue(cm.unimarc::xml) =   #{self.connection.quote(params[:frequency])}" if !params[:frequency].blank?

      invoice_select = invoice_join = invoice_group = ''
      if !params[:invoice_id].blank?
        invoice_select = invoice_group = 'abb.prezzo_in_fattura,abb.invoice_ids,'
        if invoice_filter_enabled
          if params[:invoice_id].to_i == 0
            invoice_join = "left join serial_invoices si on(si.clavis_invoice_id::text=abb.invoice_ids)"
            cond << "si.clavis_invoice_id is null"
          else
            invoice_join = "join serial_invoices si on(si.clavis_invoice_id::text=abb.invoice_ids)"
            cond << "si.clavis_invoice_id = #{params[:invoice_id].to_i}"
          end
        else
          invoice_join = ''
          with_cond << "s.serial_invoice_id is null"
        end
      else
        invoice_select = invoice_group = 'abb.prezzo_in_fattura,abb.invoice_ids,'
        invoice_join = "left join serial_invoices si on(si.clavis_invoice_id::text=abb.invoice_ids)"
      end

      cond << "st.title ~* #{self.connection.quote(params[:serial_title][:title])}" if !params[:serial_title].nil? and !params[:serial_title][:title].nil?
      
      cond = cond==[] ? '' : " AND #{cond.join(' AND ')}"
      with_cond = with_cond==[] ? '' : " AND #{with_cond.join(' AND ')}"

      sql=%Q{--      cond: #{cond}\n-- with_cond: #{with_cond}
        with abb as (
        select t.id as title_id,
                          array_to_string(array_agg(l.clavis_library_id order by nickname), ',') as libraries,
                          array_to_string(array_agg(s.numero_copie order by nickname), ',') as numero_copie,
                          array_to_string(array_agg(s.prezzo order by nickname), ',') as prezzo_in_fattura,
                          array_to_string(array_agg(s.serial_invoice_id order by nickname), ',') as invoice_ids,
  			  sum(s.numero_copie) as tot_copie,
          array_to_string(array_agg(l.nickname order by nickname), ', ') as library_names
       from serial_titles         t
        join serial_subscriptions s on (s.serial_title_id=t.id)
            join serial_libraries l on (l.clavis_library_id=s.library_id and l.serial_list_id=t.serial_list_id)
       where t.serial_list_id=#{params[:serial_list_id]} #{with_cond} group by t.id
     )
    select st.serial_list_id,st.id,cm.manifestation_id,st.title,cm.publisher,
            st.prezzo_stimato*abb.tot_copie as prezzo_totale_stimato,st.prezzo_stimato,
             st.note,st.note_fornitore,abb.libraries,abb.library_names,abb.tot_copie,abb.numero_copie,
	     #{invoice_select}
             serial_frequency_of_issue(cm.unimarc::xml) as frequency_code, freq.label as frequency_label
             #{issues_select}
            from serial_titles st
	    join abb on(abb.title_id=st.id)
            #{invoice_join}
            left join clavis.manifestation cm on(cm.manifestation_id=st.manifestation_id)
            #{issues_join}
	    left join clavis.unimarc_codes freq
        on(freq.code_value::char=serial_frequency_of_issue(cm.unimarc::xml)
             and freq.language='it_IT' and freq.field_number = 110 and freq.pos=1)
         where st.serial_list_id=#{params[:serial_list_id]}
          #{cond}
	group by st.id,cm.manifestation_id,abb.tot_copie,abb.libraries,abb.library_names,abb.numero_copie,
	       #{invoice_group}freq.label
            order by st.sortkey, lower(st.title);\n}
    end

    fd=File.open("/home/seb/serial_title_trova.sql", "w")
    fd.write(sql)
    fd.close
    self.find_by_sql(sql)
  end

  # Sigle biblioteche usate nell'archivio originale e corrispondenza con attuali library_id in Clavis
  def self.siglebib
    {
      A:10,
      B:11,
      C:8,
      D:13,
      E:14,
      F:15,
      G:27,
      H:16,
      I:17,
      L:18,
      M:19,
      N:20,
      O:21,
      Q:2,
      R:28,
      U:24,
      V:496,
      W:3
    }
  end

  def self.aggiorna_estero
    self.order(:sortkey).each do |p|
      p.aggiorna_estero
    end
  end

  def self.aggiorna_sospeso
    self.order(:id).each do |p|
      puts "aggiorno sospeso #{p.id} - #{p.title}"
      p.aggiorna_sospeso
    end
  end
  
  def self.aggiorna_serial_subscriptions
    self.order(:sortkey).each do |p|
      puts "aggiorno subscriptions #{p.id} - #{p.title}"
      p.aggiorna_serial_subscriptions
    end
    nil
  end

end
