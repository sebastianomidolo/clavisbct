class SpItem < ActiveRecord::Base
  self.table_name='sp.sp_items'

  attr_accessible :bibliography_id, :item_id, :bibdescr, :updated_at, :section_number, :colldec, :sbn_bid, :created_at, :mainentry, :collciv, :sigle, :sortkey, :note, :manifestation_id, :created_by, :updated_by

  belongs_to :sp_bibliography, :foreign_key=>'bibliography_id'
  
  # before_save :get_clavis_manifestation_data
  before_save :import_from_clavis

  def to_label
    l = self.mainentry.blank? ? self.bibdescr : "#{self.mainentry}. #{self.bibdescr}"
    "#{l[0..48]}..."
  end

  def to_html
    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("sp_item",tempdir)
    infile=tf.path
    fd = File.open(infile, 'w')
    fd.write(self.bibdescr)
    fd.close
    outfile="#{tf.path}.out"
    cmd = "/usr/local/bin/pandoc -f latex -t html #{infile} -o #{outfile}"
    data = ''
    if Kernel.system(cmd)
      fd = File.open(outfile)
      data = fd.read
      fd.close
    end
    tf.close(true)
    data
  end

  def sp_section
    return nil if self.section_number.nil?
    SpSection.find_by_number_and_bibliography_id(self.section_number,self.bibliography_id)
  end

  def thesection
    return '' if self.section_number.nil?
    self.sp_section.title
  end

  def item_brothers
    self.sp_section.nil? ? self.sp_bibliography.sp_items : self.sp_section.sp_items
  end
  def first_item
    self.item_brothers.first
  end
  def last_item
    self.item_brothers.last
  end
  def next_item
    ok = nil
    self.item_brothers.each do |i|
      (ok = true and next) if i.id==self.id
      return i if ok
    end
    nil
  end
  def previous_item
    ok = nil
    self.item_brothers.reverse.each do |i|
      (ok = true and next) if i.id==self.id
      return i if ok
    end
    nil
  end

  def published?
    self.section_number.nil? ? self.sp_bibliography.published? : self.sp_section.published?
  end

  def collocazioni
    return self.collciv if !self.collciv.blank?
    return nil if self.manifestation_id.nil?
    cond = self.sp_bibliography.library_id.blank? ? '' : "AND ci.home_library_id=#{self.sp_bibliography.library_id}"
    sql = %Q{select distinct array_to_string(array_agg(DISTINCT coll.collocazione
              ORDER BY coll.collocazione), ', ') as collocazioni from clavis.manifestation cm
        join clavis.item ci using(manifestation_id)
        join clavis.collocazioni coll using(item_id)
          WHERE cm.manifestation_id=#{self.manifestation_id} #{cond};}
    # puts sql
    self.connection.execute(sql).to_a.first['collocazioni']
  end

  def permalink
    return nil if self.manifestation_id.blank?
    "https://clavisbct.comperio.it/spl/#{self.manifestation_id}"
  end

  def clavis_manifestation
    return ClavisManifestation.find(self.manifestation_id) if !self.manifestation_id.blank?
    sql=nil
    if !self.sbn_bid.blank?
      sql=%Q{SELECT * FROM clavis.manifestation WHERE bid='#{self.sbn_bid}';}
    else
      if !self.collciv.blank?
        if !self.id.blank?
          sql=%Q{SELECT cm.* FROM sp.sp_items i
           JOIN clavis.collocazioni cc ON(i.collciv=cc.collocazione)
           JOIN clavis.item ci ON(ci.item_id=cc.item_id)
           JOIN clavis.manifestation cm ON(cm.manifestation_id=i.manifestation_id)
            WHERE ci.manifestation_id!=0 AND i.item_id='#{self.item_id}';}
        else
          sql=%Q{SELECT cm.* FROM clavis.collocazioni cc
           JOIN clavis.item ci ON(ci.item_id=cc.item_id)
           JOIN clavis.manifestation cm USING(manifestation_id)
            WHERE ci.manifestation_id!=0 AND cc.collocazione='#{self.collciv}';}
        end
      end
    end
    sql.nil? ? nil : ClavisManifestation.find_by_sql(sql).first
  end

  def import_from_clavis(md=nil)
    # return nil if !self.bibdescr.blank?
    return nil if md.nil? and self.manifestation_id.nil?
    return true if !ClavisManifestation.exists?(self.manifestation_id)
    md = ClavisManifestation.find(self.manifestation_id) if md.nil?
    puts "Importazione dati per item con manifestation_id = #{md.id}"
    return if md.unimarc.blank?
    puts "md.author: #{md.author} (mainentry: #{self.mainentry})"
    self.bibdescr=md.to_isbd if self.bibdescr.blank?
    self.sortkey=md.sort_text if self.sortkey.blank?
    self.mainentry=md.author if self.mainentry.blank?
    self.collciv = self.collocazioni
    self.sbn_bid = md.bid if md.bid_source=='SBN' and !md.bid_source.blank?
  end

  def senza_parola_item_path
    SpItem.senza_parola_item_path(self.item_id, self.bibliography_id)
  end

  def SpItem.senza_parola_item_path(item_id, bibliography_id)
    "http://biblio.comune.torino.it:8080/ProgettiCivica/SenzaParola/typo.cgi?id=#{bibliography_id}&skid=#{item_id}&rm=edit"
  end

  # Verificare se questa procedure serva davvero
  def get_clavis_manifestation_data
    return nil if self.manifestation_id.nil? and self.sbn_bid.blank?
    sql = "SELECT * FROM clavis.manifestation WHERE"
    if self.manifestation_id.nil?
      cm = ClavisManifestation.find_by_sql("#{sql} bid_source='SBN' AND bid='#{self.sbn_bid}' AND length(bid)=10 limit 1")
    else
      cm = ClavisManifestation.find_by_sql("#{sql} manifestation_id=#{self.manifestation_id}")
    end
    import_from_clavis(cm.first)
  end

  def SpItem.ricollocati_a_scaffale_aperto
    sql=%Q{select ci.custom_field1 as ex_collocazione,ci.section,ci.collocation,spi.*,
           spb.title as bibliography_title from sp.sp_items spi join clavis.item ci
        on (spi.collciv=substr(custom_field1,4))
       join sp.sp_bibliographies spb on(spb.id=spi.bibliography_id) where ci.section ~ '^CC'
      and ci.owner_library_id=2 order by spb.title, spi.sortkey}
    # SpItem.connection.execute(sql).to_a
    SpItem.find_by_sql(sql)
  end
end
