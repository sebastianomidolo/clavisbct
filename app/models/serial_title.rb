# coding: utf-8
class SerialTitle < ActiveRecord::Base
  attr_accessible :title, :manifestation_id, :sortkey, :estero, :sospeso, :updated_by, :prezzo_stimato, :note

  belongs_to :serial_list

  validates :title, presence: true
  validates_uniqueness_of :title, scope: :serial_list_id

  before_save :set_date_updated
  
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
      sql = %Q{SELECT cl.label, l.*,l.clavis_library_id as ok_library_id,s.*,ll.librarian_id as okgest
              FROM serial_libraries l LEFT JOIN #{SerialSubscription.table_name} s
                 ON(s.library_id=l.clavis_library_id and s.serial_title_id=#{self.id})
             LEFT JOIN clavis.l_library_librarian ll 
                 ON(ll.library_id = l.clavis_library_id AND ll.librarian_id=#{user.clavis_librarian.id})
             LEFT JOIN clavis.library cl ON(cl.library_id=l.clavis_library_id)
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

  def self.trova(params={},user=nil)
    cond = []
    cond << "sospeso=#{self.connection.quote(params[:sospeso])}" if !params[:sospeso].blank?
    cond << "estero=#{self.connection.quote(params[:estero])}" if !params[:estero].blank?

    if params[:library_id].to_i==-1
      cond = cond==[] ? '' : " AND #{cond.join(' AND ')}"
      sql=%Q{select st.title,st.id,st.prezzo_stimato,st.note,'[vai a acquisizioni]' as library_names,0 as count
           from #{SerialTitle.table_name} st left join #{SerialSubscription.table_name} ss
       on(st.id=ss.serial_title_id) where st.serial_list_id=#{params[:serial_list_id]}
           and ss is null #{cond} order by st.sortkey, lower(st.title);}
    else
      cond << "library_id=#{params[:library_id].to_i}" if !params[:library_id].blank?
      cond << "tipo_fornitura=#{self.connection.quote(params[:tipo_fornitura])}" if !params[:tipo_fornitura].blank?
      cond = cond==[] ? '' : " AND #{cond.join(' AND ')}"
      
      sql=%Q{with abb as (
        select t.id as title_id,array_agg(l.sigla order by nickname) as sigle,
                          array_agg(l.clavis_library_id order by nickname) as libraries,
          array_to_string(array_agg(l.nickname order by nickname), ', ') as library_names, count(*)
       from serial_titles         t
        join serial_subscriptions s on (s.serial_title_id=t.id)
            join serial_libraries l on (l.clavis_library_id=s.library_id and l.serial_list_id=t.serial_list_id)
       where t.serial_list_id=#{params[:serial_list_id]} group by t.id
     )
    select st.title,st.id,st.prezzo_stimato,st.note,abb.sigle,abb.libraries,abb.library_names,count(*)
          from serial_libraries sl join serial_subscriptions ss
              on (ss.library_id=sl.clavis_library_id)
            join serial_titles st on(st.id=ss.serial_title_id)
	    join abb on(abb.title_id=st.id)
         where sl.serial_list_id=#{params[:serial_list_id]}
          and st.serial_list_id=sl.serial_list_id
          #{cond}
          group by st.title,st.id,st.prezzo_stimato,st.note,abb.sigle,abb.libraries,abb.library_names order by st.sortkey, lower(st.title);\n}
    end
    
    fd=File.open("/home/seb/provasql.sql", "w")
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
