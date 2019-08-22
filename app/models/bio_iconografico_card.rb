# -*- coding: utf-8 -*-
class BioIconograficoCard < DObject
  attr_accessible :namespace, :intestazione, :lettera, :numero, :note, :var1, :var2, :var3, :var4, :var5,
  :qualificazioni, :seqnum, :data_nascita, :data_morte, :luogo_nascita, :luogo_morte, :altri_link,
  :luoghi_visitati, :esistenza_in_vita, :luoghi_di_soggiorno
  before_save :check_record, :bio_iconografico_topic

  def bio_iconografico_topic_show
    return nil if self.id.nil?
    sql=%Q{SELECT t.* FROM
      bio_iconografico_topics t join attachments a
        on (a.attachable_type='BioIconograficoTopic' and a.attachable_id=t.id and a.d_object_id=#{self.id})
    }
    BioIconograficoTopic.find_by_sql(sql).first
  end

  def bio_iconografico_topic
    return nil if self.id.nil?
    sql=%Q{SELECT t.* FROM
      bio_iconografico_topics t join attachments a
        on (a.attachable_type='BioIconograficoTopic' and a.attachable_id=t.id and a.d_object_id=#{self.id})
    }
    t=BioIconograficoTopic.find_by_sql(sql).first
    if !t.nil?
      if !self.intestazione.blank? and self.intestazione!=t.intestazione
        t.intestazione=self.intestazione
        t.save
      end
      return t
    end

    return if self.intestazione.blank?

    sql=%Q{select * from bio_iconografico_topics_view where intestazione=#{self.connection.quote(self.intestazione)}}

    t=BioIconograficoTopic.find_by_sql(sql).first
    if t.nil?
      # puts "creazione per intestazione #{self.intestazione}"
      t=BioIconograficoTopic.new
      t.intestazione=self.intestazione
      t.save
    end
    
    sql=%Q{INSERT INTO attachments(d_object_id,attachable_id,attachable_type) VALUES
           (#{self.id},#{t.id},'BioIconograficoTopic')}
    BioIconograficoTopic.connection.execute(sql)
    t
  end

  def check_record
    self.access_right_id=0
    mp=self.digital_objects_mount_point
    fn=self.canonical_filename
    return if fn.nil?

    r=BioIconograficoCard.find_by_filename(fn)
    if !r.nil?
      return if r.id==self.id
      fn=File.join('bct','cards', 'doppi', "#{self.id}.jpg")
      puts "Esiste già un record (#{r.id}) con nome #{self.filename}, per quello che sto salvando uso il nome univoco #{fn}"
    end

    sfn=File.join(mp, fn)
    FileUtils.mkdir_p(File.dirname(sfn))
    if !File.exists?(sfn)
      puts "sposto il file nella posizione canonica (#{sfn})"
      of=File.join(mp, self.filename)
      FileUtils.mv(of, sfn)
    end
    self.filename=fn
  end

  def canonical_filename
    return nil if self.lettera.blank? or self.numero.blank?
    if self.namespace.blank?
      "#{File.join('bct', 'bio_iconografico', self.lettera.upcase, (format "%05d", self.numero))}.jpg"
    else
      "#{File.join('bct', 'cards', self.namespace, self.lettera.upcase, (format "%05d", self.numero))}.jpg"
    end
  end

  def absolute_filepath
    BioIconograficoCard.absolute_filepath
  end

  def save_new_record(params,creator)
    uploaded_io = params[:filename]
    # fname=uploaded_io.original_filename
    fname="#{SecureRandom.urlsafe_base64}.jpg"
    mp=self.digital_objects_mount_point

    full_filename=File.join(mp, 'bct','bio_iconografico', 'upload', fname)

    # filename = full_filename.sub(mp,'')
    #r=BioIconograficoCard.find_by_filename(filename)
    #return r if !r.nil?

    File.open(full_filename, 'wb') do |file|
      file.write(uploaded_io.read)
    end
    full_filename.sub!(mp,'')
    self.filename=full_filename
    lettera=params[:lettera]
    namespace=params[:namespace]
    self.tags={l:lettera,ns:namespace,user:creator.id.to_s,
      intestazione:''}.to_xml(root:'r',:skip_instruct => true, :indent => 0)
    self.save
    self
  end

  def update_xml_from_params(params)
    self.lettera=params[:lettera]
    self.numero=params[:numero]
    self.intestazione=params[:intestazione]
  end

  def intestazione=(t) self.edit_tags(intestazione:t) end
  def lettera=(t) self.edit_tags(l:t) end
  def numero=(t) self.edit_tags(n:t) end
  def namespace=(t) self.edit_tags(ns:t) end

  def size=(t) self.edit_tags(size:t) end

  def altri_link=(t) self.edit_tags(altri_link:t) end
  def data_morte=(t) self.edit_tags(data_morte:t) end
  def data_nascita=(t) self.edit_tags(data_nascita:t) end
  def esistenza_in_vita=(t) self.edit_tags(esistenza_in_vita:t) end
  def luoghi_di_soggiorno=(t) self.edit_tags(luoghi_di_soggiorno:t) end
  def luoghi_visitati=(t) self.edit_tags(luoghi_visitati:t) end
  def luogo_morte=(t) self.edit_tags(luogo_morte:t) end
  def luogo_nascita=(t) self.edit_tags(luogo_nascita:t) end
  def note=(t) self.edit_tags(nt:t) end
  def qualificazioni=(t) self.edit_tags(qualificazioni:t) end
  def seqnum=(t) self.edit_tags(seqnum:t) end
  def var1=(t) self.edit_tags(var1:t) end
  def var2=(t) self.edit_tags(var2:t) end
  def var3=(t) self.edit_tags(var3:t) end
  def var4=(t) self.edit_tags(var4:t) end
  def var5=(t) self.edit_tags(var5:t) end


  def intestazione()
    self.xmltag('intestazione')
  end

  def lettera() self.xmltag('l') end
  def numero() self.xmltag('n') end
  def namespace() self.xmltag('ns') end

  def size() self.xmltag('size') end

  def altri_link() self.xmltag('altri_link') end
  def data_morte() self.xmltag('data_morte') end
  def data_nascita() self.xmltag('data_nascita') end
  def esistenza_in_vita() self.xmltag('esistenza_in_vita') end
  def luoghi_di_soggiorno() self.xmltag('luoghi_di_soggiorno') end
  def luoghi_visitati() self.xmltag('luoghi_visitati') end
  def luogo_morte() self.xmltag('luogo_morte') end
  def luogo_nascita() self.xmltag('luogo_nascita') end
  def note() self.xmltag('nt') end
  def qualificazioni() self.xmltag('qualificazioni') end
  def seqnum() self.xmltag('seqnum') end
  def var1() self.xmltag('var1') end
  def var2() self.xmltag('var2') end
  def var3() self.xmltag('var3') end
  def var4() self.xmltag('var4') end
  def var5() self.xmltag('var5') end

  def numero_scheda
    "#{self.xmltag('l')}_#{self.xmltag('n')}"
  end

  def namespace_to_label
    return 'non assegnato' if self.namespace.blank?
    BioIconograficoCard.namespaces[self.namespace.to_sym]
  end

  def self.lettere
    ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
  end

  def self.search_qs(qs)
    sql=%Q{select c.*,o.* from bio_iconografico_topics_view t
     join attachments a on (a.attachable_type='BioIconograficoTopic' and a.attachable_id=t.id)
     join bio_iconografico_cards c on(c.id=a.d_object_id)
     join d_objects o on(o.id=a.d_object_id)
     where t.intestazione ~* #{self.connection.quote(qs)}}
    self.find_by_sql(sql)
  end
  def self.search_topic(topic_id)
    sql=%Q{select c.*,o.* from bio_iconografico_topics_view t
     join attachments a on (a.attachable_type='BioIconograficoTopic' and a.attachable_id=t.id)
     join bio_iconografico_cards c on(c.id=a.d_object_id)
     join d_objects o on(o.id=a.d_object_id)
     where t.id=#{self.connection.quote(topic_id)}}
    self.find_by_sql(sql)
  end

  def self.search(params)
    cond = []
    namespace = params[:namespace]
    cond << "c.lettera=#{self.connection.quote(params[:lettera])}" if !params[:lettera].blank?
    cond << "t.intestazione ~* #{self.connection.quote(params[:qs])}" if !params[:qs].blank?
    cond << "t.id = #{self.connection.quote(params[:topic_id].to_i)}" if !params[:topic_id].blank?
    return [] if cond.size==0
    cond << "c.namespace=#{self.connection.quote(namespace)}" if !namespace.blank?
    cond = "WHERE #{cond.join(" and ")}"
    if !params[:lettera].blank?
      sql=%Q{select c.*,o.tags,o.name,o.d_objects_folder_id
      from bio_iconografico_cards c join d_objects o using(id)
      #{cond}
      order by lettera, numero}
    else
      sql=%Q{select c.*,o.* from bio_iconografico_topics_view t
       join attachments a on (a.attachable_type='BioIconograficoTopic' and a.attachable_id=t.id)
       join bio_iconografico_cards c on(c.id=a.d_object_id)
       join d_objects o on(o.id=a.d_object_id) #{cond} order by lettera, numero}
    end
    fd=File.open("/home/seb/log.txt", 'w')
    fd.write(sql)
    fd.close
    pp=params[:per_page].blank? ? 50 : params[:per_page]
    self.paginate_by_sql(sql, :per_page=>pp, :page=>params[:page])
  end

  def self.list(params, bio_iconografico_card=nil)
    cond = []
    if bio_iconografico_card.nil?
      namespace = params[:namespace].blank? ? 'bioico' : params[:namespace]
      cond << "b.lettera=#{self.connection.quote(params[:lettera])}"
      if !params[:numero].blank?
        cond << "b.numero>=#{self.connection.quote(params[:numero])}"
      end
      if !params[:range].blank?
        from,to=params[:range].split('-')
        cond << "b.numero between #{from} and #{to}"
      end
    else
      b=bio_iconografico_card
      namespace = b.namespace
      # cond << "b.intestazione::text ~* #{self.connection.quote(b.intestazione)}" if !b.intestazione.nil?
      cond << "o.tags::text ~* #{self.connection.quote(b.intestazione)}" if !b.intestazione.nil?
      cond << "b.numero = #{b.numero}" if !b.numero.nil?
    end

    return [] if cond.size==0
    cond << "b.namespace=#{self.connection.quote(namespace)}"
    cond = "WHERE #{cond.join(" and ")}"

    sql=%Q{select b.*,o.tags,o.name,o.d_objects_folder_id
      from bio_iconografico_cards b join d_objects o using(id)
      #{cond}
      order by lettera, numero}
    pp=params[:per_page].blank? ? 50 : params[:per_page]
    self.paginate_by_sql(sql, :per_page=>pp, :page=>params[:page])
  end

  def self.conta(params={})
    cond = params[:lettera].blank? ? '' : "AND lettera = #{self.connection.quote(params[:lettera])}"
    sql="select count(*) from bio_iconografico_cards where namespace = '#{params[:namespace]}' #{cond}"
    self.connection.execute(sql).first['count'].to_i
  end

  def self.doppi(params={})
    sql=%Q{select o.* from bio_iconografico_cards b join d_objects o using(id) where b.id in (select unnest(array_agg(id)) as ids from bio_iconografico_cards where namespace=#{self.connection.quote(params[:namespace])} and numero>0 group by lettera,numero having count(*)>1) order by lettera,numero}
    self.find_by_sql(sql)
  end

  #def self.editors
  #  # Creare un array di user_id di utenti autorizzati a modificare le schede BioIconografico
  #  # return [9,15,23]
  #  return []
  #end

  def self.senza_numero(params={})
    sql=%Q{select * from  bio_iconografico_cards b join d_objects o using(id)
     where length(lettera)!=1 OR numero is null
      order by id}
    pp=params[:per_page].blank? ? 50 : params[:per_page]
    self.paginate_by_sql(sql, :per_page=>pp, :page=>params[:page])
  end

  def self.senza_intestazione(params={})
    sql=%Q{select * from  bio_iconografico_cards b join d_objects o using(id)
     where length(lettera)!=1 OR numero is null
      order by id}
    pp=params[:per_page].blank? ? 50 : params[:per_page]
    self.paginate_by_sql(sql, :per_page=>pp, :page=>params[:page])
  end

  def self.total_filesize(params={})
    cond = params[:namespace].blank? ? '' : "WHERE b.namespace=#{self.connection.quote(params[:namespace])}"
    sql="select sum(bfilesize) as size from bio_iconografico_cards b join d_objects o using (id) #{cond}"
    self.connection.execute(sql).first['size'].to_i
  end

  def self.namespaces(user=nil)
    cond = user.nil? ? '' :  "where user_id=#{user.id}"
    sql=%Q{select distinct n.label,n.title from bio_icon_namespaces_users nu join bio_icon_namespaces n using(label)#{cond} order by n.title;}
    h=Hash.new
    self.connection.execute(sql).to_a.each do |r|
      h[r['label'].to_sym]=r['title']
    end
    return h
  end

  def BioIconograficoCard.default_namespace(user=nil)
    ns=self.namespaces(user)
    return nil if ns.first.nil?
    ns.first.first.to_s
  end

  def BioIconograficoCard.find_by_filename(fname)
    f=DObjectsFolder.find_by_name(File.dirname(fname))
    return nil if f.nil?
    BioIconograficoCard.find_by_name_and_d_objects_folder_id(File.basename(fname),f.id)
  end
end
