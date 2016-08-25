# -*- coding: utf-8 -*-
class BioIconograficoCard < DObject
  attr_accessible :intestazione, :lettera, :numero, :note, :var1, :var2, :var3, :var4, :var5,
  :qualificazioni, :seqnum, :data_nascita, :data_morte, :luogo_nascita, :luogo_morte, :altri_link,
  :luoghi_visitati, :esistenza_in_vita, :luoghi_di_soggiorno
  before_save :check_record, :bio_iconografico_topic

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
    puts sql
    t=BioIconograficoTopic.find_by_sql(sql).first
    if t.nil?
      puts "creazione per intestazione #{self.intestazione}"
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
      fn=File.join('bct','bio_iconografico', 'doppi', "#{self.id}.jpg")
      puts "Esiste già un record (#{}) con nome #{self.filename}, per quello che sto salvando uso il nome univoco #{fn}"
    end

    sfn=File.join(mp, fn)
    FileUtils.mkdir_p(File.dirname(sfn))
    if !File.exists?(sfn)
      puts "sposto il file nella posizione canonica"
      of=File.join(mp, self.filename)
      FileUtils.mv(of, sfn)
    end
    self.filename=fn
  end

  def canonical_filename
    return nil if self.lettera.blank? or self.numero.blank?
    "#{File.join('bct', 'bio_iconografico', self.lettera.upcase, (format "%05d", self.numero))}.jpg"
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
    self.tags={l:lettera,user:creator.id.to_s,
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


  def intestazione() self.xmltag('intestazione') end
  def lettera() self.xmltag('l') end
  def numero() self.xmltag('n') end

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

  def self.lettere
    ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z']
  end

  def self.list(params, bio_iconografico_card=nil)
    cond = []
    if bio_iconografico_card.nil?
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
      # cond << "b.intestazione::text ~* #{self.connection.quote(b.intestazione)}" if !b.intestazione.nil?
      cond << "o.tags::text ~* #{self.connection.quote(b.intestazione)}" if !b.intestazione.nil?
      cond << "b.numero = #{b.numero}" if !b.numero.nil?
    end

    if cond.size>0
      cond = "WHERE #{cond.join(" and ")}"
    else
      return []
    end
    sql=%Q{select b.*,o.tags,o.filename
      from bio_iconografico_cards b join d_objects o using(id)
      #{cond}
      order by lettera, numero}
    pp=params[:per_page].blank? ? 50 : params[:per_page]
    self.paginate_by_sql(sql, :per_page=>pp, :page=>params[:page])
  end

  def self.conta(params={})
    sql="select count(*) from bio_iconografico_cards where lettera = '#{params[:lettera]}'"
    self.connection.execute(sql).first['count']
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

  def self.total_filesize
    sql="select sum(bfilesize) as size from bio_iconografico_cards b join d_objects o using (id)"
    self.connection.execute(sql).first['size'].to_i
  end

end
