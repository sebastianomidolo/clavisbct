# coding: utf-8

class SerialList < ActiveRecord::Base
  attr_accessible :title, :year, :note, :locked

  has_many :serial_titles
  has_many :serial_users
  validates :title, presence: true
  validates_uniqueness_of :title

  def to_label
    "#{self.title}#{self.locked? ? ' (sola lettura)' : ''}"
  end

  def owned_by?(user)
    self.serial_users.where(user_id:user.id).size == 0 ? false : true
  end

  def subscribed_serial_titles_count
    self.connection.execute("select count(*) from serial_titles where serial_list_id = #{self.id} and id in (select serial_title_id from serial_subscriptions)").to_a.first['count'].to_i
  end
  def unsubscribed_serial_titles_count
    self.connection.execute("select count(*) from serial_titles where serial_list_id = #{self.id} and id not in (select serial_title_id from serial_subscriptions)").to_a.first['count'].to_i
  end

  def delete_libraries(library_ids)
    return false if self.locked?
    if library_ids==:all
      libcond=''
      self.delete_subscriptions(:all)
    else
      libcond="AND clavis_library_id IN (#{library_ids.join(',')})"
      self.delete_subscriptions(library_ids)
    end

    sql=%Q{DELETE FROM #{SerialLibrary.table_name} WHERE serial_list_id=#{self.id} #{libcond};}
    puts sql
    self.connection.execute(sql)
  end

  def delete_titles
    return false if self.locked?
    sql=%Q{DELETE FROM #{SerialTitle.table_name} WHERE serial_list_id=#{self.id}
           AND id NOT IN (select serial_title_id FROM #{SerialSubscription.table_name} WHERE serial_list_id=#{self.id});}
    self.connection.execute(sql)
  end

  def delete_subscriptions(library_ids)
    return false if self.locked?
    if library_ids==:all
      libcond=''
    else
      libcond="AND library_id IN (#{library_ids.join(',')})"
    end
    sql=%Q{
      DELETE FROM #{SerialSubscription.table_name} WHERE
        serial_title_id in (SELECT id from #{SerialTitle.table_name} WHERE serial_list_id=#{self.id} #{libcond});}
    self.connection.execute(sql)
  end

  def import_data(sourcefile)
    self.import_file=sourcefile
    self.locked=true

    if File.exists?("#{self.import_file}-siglebib")
      self.libraries_file="#{self.import_file}-siglebib"
    else
      self.libraries_file=File.join(File.dirname(self.import_file), 'siglebib-default.txt')
    end
    self.save

    conn=ActiveRecord::Base::connection
    sql = []
    File.read(self.libraries_file).each_line do |l|
      sigla,id,nick = l.split
      sql << "INSERT INTO #{SerialLibrary.table_name} (serial_list_id,sigla,clavis_library_id,nickname) VALUES(#{self.id},#{conn.quote(sigla)},#{id.to_i},#{conn.quote(nick)});"
    end
    # return sql.join("\n");
    
    data=File.read(sourcefile)
    data=Iconv.conv('utf-8', 'iso-8859-15', data)
    ds=data.split("TI_ ")
    ds.shift
    ds.each do |r|
      line = conn.quote("TI_ #{r.gsub('\n','\r').strip}")
      sql << %Q{INSERT INTO #{SerialTitle.table_name} (serial_list_id,textdata) values (#{self.id},#{line});}
    end
    sql.join("\n")
    conn.execute(sql.join("\n"))
    self.update_attributes_from_textdata
  end

  def library_select
    options=SerialLibrary.clavis_libraries(self.id, 'label').collect {|i| [i.label,i.clavis_library_id]}
    options.unshift ['Titoli non acquisiti',-1]
  end

  def subscription_select
    [['Da decidere', 'i'],['Edicola (g)','g'],['Abbonamento (a)','a'],['Dono (d)','d'],['Supplemento (s)','s'],['CR (?)', 'C']]
  end

  def clone_from_list(sourcelist_id)
    sql=%Q{INSERT INTO #{SerialTitle.table_name} (serial_list_id, title, sospeso, estero, manifestation_id, note, sortkey, prezzo_stimato)
  (select #{self.id}, title, sospeso, estero, manifestation_id, note, sortkey, prezzo_stimato
          FROM #{SerialTitle.table_name} where serial_list_id = #{sourcelist_id});
    INSERT INTO #{SerialSubscription.table_name} (serial_title_id,library_id,note,tipo_fornitura)
        (select t2.id,s.library_id,s.note,s.tipo_fornitura FROM #{SerialTitle.table_name} t1
         JOIN #{SerialTitle.table_name} t2 using(title)
      JOIN #{SerialSubscription.table_name} s ON (s.serial_title_id=t1.id)
          WHERE t1.serial_list_id=#{sourcelist_id} and t2.serial_list_id=#{self.id});
    INSERT INTO #{SerialLibrary.table_name} (serial_list_id, clavis_library_id, sigla, nickname)
         (SELECT #{self.id}, clavis_library_id, sigla, nickname
          FROM #{SerialLibrary.table_name} where serial_list_id = #{sourcelist_id});}
    self.connection.execute(sql)
  end

  def sum_prezzo_stimato(params={})
    cond = []
    if !params[:library_id].blank?
      cond << "ss.library_id=#{params[:library_id].to_i}"
    end
    if !params[:tipo_fornitura].blank?
      tf = params[:tipo_fornitura].split(',').collect {|x| self.connection.quote(x)}
      cond << "ss.tipo_fornitura IN (#{tf.join(',')})"
    end
    if !params[:estero].blank?
      cond << "st.estero = #{self.connection.quote(params[:estero])}"
    end
    if !params[:sospeso].blank?
      cond << "st.sospeso = #{self.connection.quote(params[:sospeso])}"
    end
    cond = cond.join(' and ')
    cond = "AND #{cond}" if cond!=''
    sql = %Q{select sum(prezzo_stimato*numero_copie)::numeric
          FROM serial_titles st JOIN serial_subscriptions ss ON(ss.serial_title_id=st.id)
            WHERE st.serial_list_id=#{self.id} #{cond}}
    res=self.connection.execute(sql).to_a.first['sum']
    res.nil? ? 0 : res
  end

  def formula_titolo(params={}, sep=' - ')
    return self.title if params=={}
    res=[]
    res << self.title
    res << (ClavisLibrary.find(params[:library_id]).shortlabel) if params[:library_id].to_i > 0
    res << (params[:estero]=='t' ? "Titoli stranieri" : "Titoli italiani") if !params[:estero].blank?
    if !params[:tipo_fornitura].blank?
      res << SerialList.subscription_types[params[:tipo_fornitura].to_sym]
    end
    res.join(sep)
  end

  def update_attributes_from_textdata
    errors = []
    self.serial_titles.each do |p|
      begin
        p.title=p.get_field('TI_ ').first
        p.sortkey=p.get_field('K: ').first
        p.save!
        p.aggiorna_estero
        p.aggiorna_sospeso
        p.aggiorna_serial_subscriptions
      rescue
        errors << "Errore su per_id #{p.id} => #{$!}"
      end
    end
    if errors.size>1
      fd=File.open("/home/seb/import_periodici_#{self.id}", "w")
      fd.write(errors.join("\n"))
      fd.close
    end
  end

  def self.lista(params={},user=nil)
    innerjoin = user.nil? ? '' : "join #{SerialUser.table_name} su on(su.user_id=#{user.id} and su.serial_list_id=sl.id)"
    sql=%Q{select sl.id,sl.title,sl.year,sl.note,sl.locked,count(st.id)
            FROM #{self.table_name} sl left join #{SerialTitle.table_name} st on(st.serial_list_id=sl.id)
            #{innerjoin}
            group by sl.id,sl.title,sl.year,sl.note,sl.locked order by sl.year,sl.title}
    puts sql
    self.find_by_sql(sql)
  end

  def self.subscription_types
    {
      a:'Abbonamento',
      g:'Edicola',
      i:'Da decidere',
      d:'Dono',
    }
  end
end
