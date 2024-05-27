# coding: utf-8
class SbctTitle < ActiveRecord::Base

  self.table_name='sbct_acquisti.titoli'
  self.primary_key = 'id_titolo'

  before_save :add_timestamp
  after_save :update_purchase_proposals
  after_save :log_changes
  
  attr_accessible :id_titolo, :manifestation_id, :titolo, :autore, :editore, :collana, :prezzo, :utente, :id_tipo_titolo, :isbn, :wrk, :def, :clavis_library_ids, :sbct_list_ids, :ean, :target_lettura, :reparto, :sottoreparto, :created_by, :note, :target_lettura, :anno, :crold_notes, :age, :keywords

  attr_accessor :current_user

  validates :titolo, presence: true

  # age: età in giorni della data di pubblicazione rispetto a oggi
  # datains: età in giorni della data di inserimento in tabella titoli rispetto a oggi
  attr_accessor :fornitore, :age, :datains, :inliste, :budget

  belongs_to :sbct_tipo_titolo, :foreign_key=>'id_tipo_titolo'
  belongs_to :clavis_manifestation, foreign_key:'manifestation_id'
  has_and_belongs_to_many(:sbct_lists, join_table:'sbct_acquisti.l_titoli_liste',
                          :foreign_key=>'id_titolo',
                          :association_foreign_key=>'id_lista')

  has_and_belongs_to_many(:clavis_libraries, join_table:'sbct_acquisti.copie',
                          :foreign_key=>'id_titolo',
                          :association_foreign_key=>'library_id')

  has_and_belongs_to_many(:purchase_proposals, join_table:'sbct_acquisti.l_clavis_purchase_proposals_titles',
                          :class_name=>ClavisPurchaseProposal,
                          :foreign_key=>'id_titolo',
                          :association_foreign_key=>'proposal_id')
  has_and_belongs_to_many(:sbct_events, join_table:'sbct_acquisti.l_events_titles',
                          :foreign_key=>'id_titolo',
                          :association_foreign_key=>'event_id')


  def log_changes
    return if !self.changed?
    if self.current_user.nil?
      self.current_user=User.find(216)
    end
    data = self.changes.to_json
    sql = %Q{INSERT INTO sbct_acquisti.changes (object_class, object_id, updated_by, data)
                    VALUES('#{self.class}', #{self.id}, #{self.current_user.id}, #{self.connection.quote(data)});}
    self.connection.execute(sql)
  end

  def compatta_qualificazioni
    [self.keywords,self.reparto,self.sottoreparto].compact.join(' ; ')
  end

  def save_before_delete(user_id,notes=nil)
    data = self.attributes
    data.delete_if{|k,v| v.blank?}
    data = data.to_json
    notes = notes.blank? ? 'NULL' : self.connection.quote(notes)
    sql = %Q{INSERT INTO sbct_acquisti.deleted (object_class, object_id, deleted_by, data, notes)
                    VALUES('#{self.class}', #{self.id}, #{user_id}, #{self.connection.quote(data)}, #{notes});}
    self.connection.execute(sql)
  end

  def order_details(numerobolla=nil)
    cond = numerobolla.nil? ? '' : "and numerobollaconsegna=#{numerobolla.to_i}"
    sql = %Q{select quantità,evaso,dataordine,datainviomerce,datafattura,numerofattura,stato,statoeditoriale,cliente,
  riferimentoordine,progressivoordine,prezzo,netto,numerobollaconsegna,note
   from sbct_acquisti.report_logistico where id_titolo = #{self.id} #{cond}
        order by dataordine,datainviomerce,datafattura,numerobollaconsegna}
    puts sql
    SbctTitle.find_by_sql(sql)
  end
  def delivery_note_details(numerobolla=nil)
    self.order_details(numerobolla).first
  end
  def editable?(user)
    if (user.role?('AcquisitionStaffMember') or user.role?('AcquisitionManager')) \
      or (user.role?('AcquisitionLibrarian'))
      true
    else
      false
    end
  end

  def find_by_ean_or_insert_from_clavis(user)
    return "" if !SbctTitle.is_ean?(self.ean)
    t=SbctTitle.find_by_ean(self.ean)
    return t if !t.nil?
    sql=%Q{select * from clavis.manifestation where '#{self.ean}' IN ("ISBNISSN","EAN");}
    rec = self.connection.execute(sql).to_a
    return "Presenti in Clavis #{rec.size} titoli con EAN #{self.ean}" if rec.size!=1
    rec = rec.first
    if !(rec['bib_level'] == 'm' and rec['bib_type'] == 'a01')
      return "Non importo manifestation #{rec['manifestation_id']} con bib_level #{rec['bib_level']} e bib_type #{rec['bib_type']}"
    end

    if rec['edition_language']!='ita'
      # return "Non importo manifestation #{rec['manifestation_id']} con edition_language #{rec['edition_language']}"
    end

    t=SbctTitle.new(titolo:rec['title'],
                    autore:rec['author'],
                    editore:rec['publisher'],
                    ean:rec['EAN'],
                    isbn:rec['ISBNISSN'],
                    anno:rec['edition_date'],
                    manifestation_id:rec['manifestation_id'],
                    note:"Titolo importato da Clavis a seguito di ricerca per EAN #{self.ean} effettuata da #{user.email} - #{Time.now.to_date}"
                   )
    t.date_created=Time.now
    u = User.find_by_email('system')
    t.created_by = u.id if u.class==User
    t.current_user = u if u.class==User
    t.save
    t
  end

  def info_deleted_record
    self.connection.execute(%Q{select * from sbct_acquisti.deleted where object_class='SbctTitle' and notes = 'confluito in #{self.id}'}).first
  end

  # has_many :sbct_items, :foreign_key=>'id_titolo', include:[:sbct_budget]
  def sbct_items
    sql = %Q{select cp.*,lc.label as siglabib from sbct_acquisti.copie cp
        join clavis.library cl on(cl.library_id=cp.library_id)
        join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
         where id_titolo=#{self.id} order by lc.label;}
    sql = %{select cp.*,lc.label as siglabib,lc2.label as dest_siglabib,os.label as order_status_label,
       ord.inviato, ord.order_date as data_ordine
      from sbct_acquisti.copie cp
        join clavis.library cl on(cl.library_id=cp.library_id)
        left join clavis.library cl2 on(cl2.library_id=cp.home_library_id)
        join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
	left join sbct_acquisti.library_codes lc2 on(lc2.clavis_library_id=cl2.library_id)
        left join sbct_acquisti.order_status os on(os.id=cp.order_status)
        left join sbct_acquisti.orders ord using(order_id)
         where id_titolo=#{self.id} order by lc.label;}
    # puts sql
    SbctItem.find_by_sql(sql)
  end

  def clavis_purchase_proposals
    sql = %Q{select cpp.*, lv.value_label as stato_proposta,cp.barcode as patron_barcode,cl.library_id, lc.label as preferred_library
      FROM clavis.purchase_proposal cpp join sbct_acquisti.l_clavis_purchase_proposals_titles ppt using(proposal_id)
        join clavis.lookup_value lv ON(lv.value_key=cpp.status AND lv.value_class = 'PROPOSALSTATUS' AND value_language='it_IT')
        join clavis.patron cp using(patron_id)
        join clavis.library cl on (cl.library_id=cp.preferred_library_id)
        join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
     where ppt.id_titolo = #{self.connection.quote(self.id_titolo)} order by cpp.proposal_date desc}
    # puts sql
    ClavisPurchaseProposal.find_by_sql(sql)
  end

  def add_to_sbct_list(list_id, user_id)
    self.connection.execute "INSERT INTO sbct_acquisti.l_titoli_liste (id_titolo,id_lista,date_created,created_by) VALUES(#{self.id},#{list_id},now(),#{user_id}) on conflict(id_titolo,id_lista) do nothing"
  end

  def remove_from_sbct_list(sbct_list)
    self.sbct_lists.delete(sbct_list)
  end

  def copie
    []
  end

  def vrfy_dup(unique_field='ean')
    sql = %Q{select count(#{unique_field}) from sbct_acquisti.titoli where #{unique_field} in (select #{unique_field} from sbct_acquisti.titoli where id_titolo=#{self.id});}
    puts sql
    self.connection.execute(sql).first['count'].to_i
  end

  def elimina_duplicato(titolo_duplicato_da_eliminare, user_id)
    titolo_duplicato_da_eliminare.save_before_delete(user_id,"confluito in #{self.id}")
    sql = %Q{begin;
      update sbct_acquisti.copie set id_titolo = #{self.id} where id_titolo = #{titolo_duplicato_da_eliminare.id};
      insert into sbct_acquisti.l_titoli_liste (id_titolo,id_lista) (select #{self.id},id_lista
        from sbct_acquisti.l_titoli_liste where id_titolo=#{titolo_duplicato_da_eliminare.id}) on conflict(id_titolo,id_lista) do nothing;
      delete from sbct_acquisti.l_titoli_liste where id_titolo=#{titolo_duplicato_da_eliminare.id};
      update sbct_acquisti.l_titoli_liste set id_titolo = #{self.id} where id_titolo = #{titolo_duplicato_da_eliminare.id};
      delete from sbct_acquisti.titoli where id_titolo=#{titolo_duplicato_da_eliminare.id};
      commit;}
    self.connection.execute(sql)
  end

  def is_parent?
    cnt=self.connection.execute("select count(id_titolo) from sbct_acquisti.titoli where parent_id = #{self.id}").first['count'].to_i
    cnt > 0 ? true : false
  end

  def parent_title
    raise "il record #{self.id} ha parent_id NULL" if self.parent_id.nil?
    SbctTitle.find(self.parent_id)
  end

  def sbct_titles
    SbctTitle.find_by_sql("select * from sbct_acquisti.titoli where parent_id = #{self.id} order by naturalsort(trim(titolo))") 
  end

  def tipo_titolo_to_label
    return nil if self.id_tipo_titolo.nil?
    self.connection.execute("select tipo_titolo as t from sbct_acquisti.tipi_titolo where id_tipo_titolo='#{self.id_tipo_titolo}'").first['t']
  end

  # Non usata, fa riferimento a una tabella nel db cr_acquisti che non è più in uso da settembre 2022
  def clavis_patrons
    return []
    sql=%Q{select l.*,al.data_richiesta_lettore,al.id_acquisti,cp.lastname,cp.name,cp.patron_id,cp.barcode
              from cr_acquisti.acquisti_lettore al join cr_acquisti.t_lettore l on (l.idlettore=al.id_lettore)
           left join clavis.patron cp on (lower(cp.barcode)=lower(l.cognome)) where id_acquisti = #{self.id};}
    puts sql
    self.connection.execute(sql).to_a
  end

  def clavis_sql_items_insert
    res = []
    self.sbct_items.each do |r|
      res << %Q{INSERT INTO item (manifestation_id) VALUES(#{self.manifestation_id});}
    end
    res.join("\n")
  end

  def find_best_budget(library_id)
    if self.reparto=='RAGAZZI'
      cond = "label ~* 'ragazzi'"
    else
      cond = "not label ~* 'ragazzi'"
    end
    sql = "select * from public.pac_budgets where not locked and library_id=#{library_id} and #{cond}"
    sql = "select * from public.pac_budgets where not locked and library_id=#{library_id} and ((#{cond} and supplier_id notnull) or supplier_id is null)";
    sql = "select * from public.pac_budgets where not locked and library_id=#{library_id} and ((#{cond} and supplier_id notnull))";
    SbctBudget.find_by_sql(sql).first
  end

  def add_timestamp
    self.sbct_items.collect{|r| r.current_user=self.current_user;r.save} if !self.id_titolo.nil?
    if self.date_created.nil?
      if self.id.nil?
        self.date_created = Time.now
      else
        self.date_created = Time.now if self.id > 406040
      end
    else
      # raise 'temp error'
      self.date_updated = Time.now
    end
    self.reparto=nil if self.reparto.blank?
    self.note=nil if self.note.blank?
    self.target_lettura=nil if self.target_lettura.blank?

    if !self.ean.blank?
      self.ean=self.ean.strip 
      self.ean=self.ean.gsub(/-| /,'')
    end
    self.ean=nil if self.ean.blank?

    if !self.isbn.blank?
      self.isbn=self.isbn.strip
      self.isbn=self.isbn.gsub(/-| /,'')
    end
    self.isbn=nil if self.isbn.blank?
    self.ean = self.isbn if self.ean.nil? and !self.isbn.nil?
    self.isbn = self.ean if self.isbn.nil? and !self.ean.nil?
    self.manifestation_id=nil if self.manifestation_id==0
                                 
    SbctItem.set_clavis_item_ids(self.id) if !self.id.nil?
    SbctTitle.update_publication_year(self.id) if !self.datapubblicazione.nil?
    self.manifestation_id = get_manifestation_id_from_isbn(self.ean) if (self.manifestation_id.nil? && !self.ean.blank?)
    true
  end

  # Controlli sulla data di pubblicazione (anno)
  def repair
    puts "anno: #{self.anno.class}"
    if !self.datapubblicazione.nil? and self.anno.nil?
      puts "data di pubblicazione esiste, ma non esiste anno: #{self.datapubblicazione}"
      self.anno = self.datapubblicazione.year
      self.datapubblicazione = nil
      puts "anno: #{self.anno.class}"
    end
    if self.anno.nil?
      # self.statoeditoriale = nil if self.statoeditoriale == "Prossima Pubblicazione"
      return self
    end
    diff = anno - Time.now.year
    puts "anno corrente: #{Time.now.year} - anno di pubblicazione per #{self.id}: #{self.anno} - differenza #{diff}"
    if diff > 0
      puts "aggiusto anno di pubblicazione"
      self.anno = nil
      self.datapubblicazione = nil
      # self.statoeditoriale = "Da verificare (ultima verifica: #{Time.now})"
      # self.statoeditoriale = "Verificare la data di pubblicazione"
      self.statoeditoriale = ""
    else
      puts "anno di pubblicazione ok"
      # self.statoeditoriale = nil if self.statoeditoriale == "Prossima Pubblicazione"
    end
    self
  end

  def update_purchase_proposals
    sql=%Q{
      update clavis.purchase_proposal pp set sbct_title_id = t.id_titolo from sbct_acquisti.titoli t where t.id_titolo=#{self.id} and t.ean=pp.ean;
      delete from sbct_acquisti.l_clavis_purchase_proposals_titles where id_titolo=#{self.id};
      insert into sbct_acquisti.l_clavis_purchase_proposals_titles (id_titolo,proposal_id)
        (select sbct_title_id,proposal_id from clavis.purchase_proposal where sbct_title_id notnull)
          on conflict do nothing;}
    begin
      self.connection.execute(sql)
    rescue
      # puts("-- #{Time.now} id_titolo #{self.id} error: #{$!}\n")
      fd = File.open('/home/seb/logs/update_purchase_proposals.log', 'a')
      fd.write("-- #{Time.now} id_titolo #{self.id} error: #{$!}\n")
      fd.close
    end
    true
  end

  def get_manifestation_id_from_isbn(isbn)
    sql=%Q{select manifestation_id as id from clavis.manifestation where "ISBNISSN" = #{self.connection.quote(isbn)}}
    # raise sql
    r=self.connection.execute(sql).to_a.first
    r.nil? ? nil : r['id'].to_i
  end

  def esemplari_presenti_in_clavis
    sql=%Q{select distinct ci.item_id,ci.home_library_id,cl.label,lc.label as siglabct, status.value_label as item_status,
             source.value_label as item_source,cc.collocazione,
            ci.supplier_id, ci.inventory_date, ci.inventory_serie_id || '-' || ci.inventory_number as serieinv
     from sbct_acquisti.titoli t left join sbct_acquisti.copie c using(id_titolo)
    join clavis.item ci using(manifestation_id)
         join clavis.library cl on(cl.library_id = ci.home_library_id) 
         join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
 join clavis.lookup_value status on(status.value_key=ci.item_status and status.value_language = 'it_IT' and status.value_class = 'ITEMSTATUS') 
left join clavis.lookup_value source on(source.value_key=ci.item_source and source.value_language = 'it_IT' and source.value_class = 'ITEMSOURCE')
left join clavis.collocazioni cc using(item_id)
where t.id_titolo = #{self.id} and ci.item_status != 'E'
-- and c.library_id!=1 
order by siglabct;}
    # puts sql
    self.connection.execute(sql).to_a
  end

  def siglebct
    self.sbct_items.collect {|i| ClavisLibrary.siglabct(i.library_id)}.sort.join(', ')
  end

  def browse_object(cmd,ids)
    return if ids.nil?
    sbct_title_id=nil
    case cmd
    when 'prev'
      return nil if self.id == ids.first
      sbct_title_id = ids[ids.index(self.id)-1]
    when 'next'
      return nil if self.id == ids.last
      sbct_title_id = ids[ids.index(self.id)+1]
    when 'first'
      sbct_title_id = ids.first
    when 'last'
      sbct_title_id = ids.last
    else
      raise "browse_object('prev'|'next'|'first'|'last')"
    end
    sbct_title_id.nil? ? nil : SbctTitle.find(sbct_title_id)
  end

  # Sintassi "nome_campo:valore" presente in titolo
  # Esempio: "note:crescere con i libri" diventa ricerca per note
  def split_query
    return self if self.titolo.nil?
    tit = self.titolo.strip
    cnt=0
    title = ''
    tit.split(';').each do |t|
      t.strip!
      i = t.index(':')
      next if i.nil?
      attr = t[0..i-1]
      attr.strip!
      next if !self.respond_to?(attr)
      cnt += 1
      value = t[i+1..t.size]
      value.strip!
      # puts "attr: '#{attr}' - value: '#{value}'"
      case attr
      when 'prezzo'
        self.crold_notes = value
      else
        eval %Q{self.#{attr}="#{value}"}
      end
      title = value if attr=='titolo'
    end
    self.titolo=title if cnt>0
    self
  end

  def collocazione_decentrata(esemplari_in_clavis=nil)
    return '' if self.manifestation_id.nil?
    sql=%Q{select main_entry,dewey,concat_ws('.', dewey,upper(substr(main_entry,1,3))) as collocazione
         FROM sbct_acquisti.pac_collocazione_dewey WHERE manifestation_id=#{self.manifestation_id};}
    res=self.connection.execute(sql).first
    return '' if res.nil?
    coll=''
    esemplari_in_clavis=self.esemplari_presenti_in_clavis if esemplari_in_clavis.nil?
    if self.reparto=='RAGAZZI'
      if self.sottoreparto=='Fiction'
        coll_in_clavis=esemplari_in_clavis.collect.each {|i| i['collocazione'] if i['collocazione']=~/^RN/}.compact.uniq.first
        if coll_in_clavis.blank?
          # coll_in_clavis=esemplari_in_clavis.collect.each {|i| i['collocazione']}.compact.uniq
          coll_in_clavis=esemplari_in_clavis.collect.each {|i| next if i['siglabct']=='Q'; i['collocazione']}.compact.uniq
          return "Narrativa ragazzi: collocazioni utilizzate: #{coll_in_clavis.join(' ; ')}"
        else
          code=coll_in_clavis.split('.')[1]
          label = self.connection.execute("select label from sbct_acquisti.nr_codes where code=#{self.connection.quote(code)}").first
          label =  label.nil? ? '' : " (#{label['label']})"
          return "#{coll_in_clavis}#{label}"
        end
      else
        coll_in_clavis=esemplari_in_clavis.collect.each {|i| i['collocazione'] if i['collocazione']=~/^R\./}.compact.uniq.first
        return coll_in_clavis if !coll_in_clavis.blank?
        coll<<'R.'
      end
    else
      coll_in_clavis=esemplari_in_clavis.collect.each {|i| i['collocazione']}.compact.uniq.first
      return coll_in_clavis if !coll_in_clavis.blank?
    end
    if self.reparto=='NARRATIVA'
      coll << "N.#{res['main_entry'][0..3].upcase}"
      return coll
    end
    coll << "(Dewey mancante)" if res['dewey'].blank?

    coll<<res['collocazione']

    coll_in_clavis=esemplari_in_clavis.collect.each {|i| i['collocazione']}.compact.uniq
    coll<< " - [#{coll_in_clavis.join(' ; ')}]"
  end
  
  def SbctTitle.without_list
    self.find_by_sql "select t.* from #{self.table_name} t left join #{SbctLTitleList.table_name} tl on(tl.id_titolo=t.id_titolo) where tl.id_titolo is null"
  end

  def SbctTitle.create_fulltext_index
    self.connection.execute "DROP INDEX IF EXISTS sbct_acquisti.sbct_titles_fts_idx"
    self.connection.execute "CREATE INDEX sbct_titles_fts_idx ON sbct_acquisti.titoli USING gist (#{SbctTitle.fulltext_attributes})"
  end

  def SbctTitle.fulltext_attributes(table_alias='')
    %Q{ (
         to_tsvector('simple', coalesce(autore, ''))    ||
         to_tsvector('simple', coalesce(titolo, ''))    ||
         to_tsvector('simple', coalesce(collana, ''))    ||
         to_tsvector('simple', coalesce(editore, ''))    ||
         to_tsvector('simple', coalesce(isbn, ''))    ||
         to_tsvector('simple', coalesce(#{table_alias}ean, '')) ||
         to_tsvector('simple', coalesce(#{table_alias}note, ''))
         ) }
  end

  def SbctTitle.fulltext_attributesxx(table_alias='')
    %Q{ (
         to_tsvector('italian', coalesce(autore, ''))    ||
         to_tsvector('italian', coalesce(titolo, ''))    ||
         to_tsvector('italian', coalesce(collana, ''))    ||
         to_tsvector('italian', coalesce(editore, ''))    ||
         to_tsvector('italian', coalesce(isbn, ''))    ||
         to_tsvector('italian', coalesce(#{table_alias}ean, '')) ||
         to_tsvector('italian', coalesce(note, ''))
         ) }
  end

  
  def SbctTitle.update_manifestation_ids
    self.connection.execute(self.sql_for_update_manifestation_ids)
  end
  def SbctTitle.sql_for_update_manifestation_ids
    %Q{
     update #{SbctTitle.table_name} as t set manifestation_id = cm.manifestation_id from clavis.manifestation cm where t.manifestation_id is null and cm."ISBNISSN" = t.isbn;
     update #{SbctTitle.table_name} as t set manifestation_id = cm.manifestation_id from clavis.manifestation cm where t.manifestation_id is null and cm."ISBNISSN" = t.ean;
     update #{SbctTitle.table_name} as t set manifestation_id = cm.manifestation_id from clavis.manifestation cm where t.manifestation_id is null and cm."EAN" = t.ean;
     update #{SbctTitle.table_name} as t set manifestation_id = cm.manifestation_id from clavis.manifestation cm where t.manifestation_id is null and cm."EAN" = t.isbn;
    }
  end
  

  def SbctTitle.libraries_select(user=nil)
    if user.nil?
      ids = ''
    else
      ids = user.clavis_libraries.collect{|l| l.library_id}
      ids = "and library_id in (#{ids.join(',')})"
    end
    # library_status = "and cl.library_status='A'"
    library_status = ''
    sql=%Q{select library_id as key,lc.label || ' (' || substr(cl.label,6) || ')' as label
         FROM sbct_acquisti.library_codes lc join clavis.library cl on(cl.library_id=lc.clavis_library_id)
            WHERE lc.pac is true #{ids} #{library_status} order by lc.label;}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

  def SbctTitle.import_mdb(mdbfile)
    include AccessImport
    puts "In SbctTitle.import_mdb #{mdbfile} DISABILITATO 8 settembre 2022"
    return
    af=AccessImport::AccessFile.new(mdbfile)
    File.delete(af.sql_outfilename) if File.exists?(af.sql_outfilename)
    af.create_pg_schema
    af.tables.each do |t|
      puts "tabella #{t}"
      af.drop_pg_table(t)
      af.create_pg_table(t)
      af.sql_copy(t)
    end
    config = Rails.configuration.database_configuration
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]
    # cmd=%Q{cat mdb_export_*.sql | psql --quiet --no-psqlrc #{dbname} #{username} -f -; rm -f mdb_export_*.sql}
    cmd=%Q{cat mdb_export_*.sql | psql --quiet --no-psqlrc #{dbname} #{username} -f -}
    puts cmd
    Kernel.system(cmd)


    # email di Cosimo Palumbo 20 giugno 2022
    # Ciao Giorgio,
    #   contrariamente a quanto scritto in precedenza, da adesso la sede Ginzburg entrerà nel programma solamente con
    # login: G
    # password: G
    # e selezionerà i libri che si vedranno poi nella lista generale con "G" e non più con "GIN", che non ci sarà più,
    # quindi noi sapremo che "G" corrisponderà alla sede "Ginzburg".
    # Mentre per Centro Interculturale continuerà ad entrare con "CI".
    # Puoi avvertire le sedi.
    # Ho utilizzato la lettera "G" per semplicità, poichè non era utilizzata ed era stata tenuta per un utilizzo futuro.
    
    self.connection.execute(
      %Q{
         insert into  cr_acquisti.tipo_riga (tipo_riga , descrizione_riga) values ('E', 'Proposte esterne');
         insert into  cr_acquisti.tipo_riga (tipo_riga , descrizione_riga) values ('G', 'Tipo riga G - da interpretare');
         insert into  cr_acquisti.tipo_riga (tipo_riga , descrizione_riga) values ('K', 'Tipo riga K ebook');
         insert into  cr_acquisti.tipo_riga (tipo_riga , descrizione_riga) values ('V', 'Tipo riga V video');
         insert into  cr_acquisti.tipo_riga (tipo_riga , descrizione_riga) values ('X', 'Tipo riga X - da interpretare');
         update cr_acquisti.tipo_riga set descrizione_riga = 'Ragazzi' where tipo_riga='R';
         -- alter table cr_acquisti.acquisti rename COLUMN g to gin;
         -- alter table cr_acquisti.acquisti rename COLUMN alo to ci;
      }
    )
    # Attenzione: la tabella originale di acquisti (prima della email di Cosimo del 20 giugno 2022)
    # => Gin corrisponde a CI 
    # => Ci  corrisponde a ALO
  end

  def sistema_centrorete_url
    return nil if !self.created_by.nil?
    "http://161.97.77.68/acquisti/MANUTENZIONE_modifica_sedi.aspx?id=#{self.id}&banner=false"
  end

  def SbctTitle.users
    sql = %Q{
     select u.id,cl.name,cl.lastname,cl.username,u.email,
             array_to_string(array_agg(r.name order by r.name),', ') as role_names,
             array_to_string(array_agg(ru.role_id order by ru.role_id),', ') as this_user_roles
       from public.roles_users ru join public.users u on (u.id=ru.user_id) join public.roles r on(r.id=ru.role_id)
        join clavis.librarian cl on(cl.username=u.email) 
         where r.name ~ '^Acquisition'
        group by u.id,cl.name,cl.lastname,cl.username
        order by cl.lastname;
   }
    User.find_by_sql(sql)
  end

  def SbctTitle.target_lettura_select(params={})
    id_lista = params[:id_lista].to_i
    if id_lista == 0
      join_cond = 'WHERE'
    else
      list_ids=''
      l=SbctList.find(id_lista)
      list_ids=l.descendants.collect {|x| x['descendant_id'].to_i}.join(',')
      join_cond = "JOIN sbct_acquisti.l_titoli_liste USING(id_titolo) WHERE id_lista in (#{list_ids}) AND"
    end
    sql=%Q{select target_lettura as key,target_lettura as label, count(*) from sbct_acquisti.titoli #{join_cond} target_lettura notnull group by target_lettura order by target_lettura;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['count']} titoli)"
      res << [label,r['key']]
    end
    res
  end

  def SbctTitle.reparto_select(params={})
    id_lista = params[:id_lista].to_i
    if id_lista == 0
      join_cond = 'WHERE'
    else
      list_ids=''
      l=SbctList.find(id_lista)
      list_ids=l.descendants.collect {|x| x['descendant_id'].to_i}.join(',')
      join_cond = "JOIN sbct_acquisti.l_titoli_liste USING(id_titolo) WHERE id_lista in (#{list_ids}) AND"
    end

    sql=%Q{select reparto as key, reparto as label, count(*) from sbct_acquisti.titoli #{join_cond} reparto notnull group by reparto order by reparto;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['count']} titoli)"
      res << [label,r['key']]
    end
    res
  end

  def SbctTitle.sottoreparto_select(params={}, reparto='')
    return [] if reparto.blank?
    reparto = "AND reparto=#{self.connection.quote(reparto)}"

    id_lista = params[:id_lista].to_i
    if id_lista == 0
      join_cond = 'WHERE'
    else
      list_ids=''
      l=SbctList.find(id_lista)
      list_ids=l.descendants.collect {|x| x['descendant_id'].to_i}.join(',')
      join_cond = "JOIN sbct_acquisti.l_titoli_liste USING(id_titolo) WHERE id_lista in (#{list_ids}) AND"
    end
    
    sql=%Q{select sottoreparto as key, sottoreparto as label, count(*)
      from sbct_acquisti.titoli #{join_cond} reparto notnull and sottoreparto notnull #{reparto}
     group by reparto,sottoreparto order by reparto, sottoreparto NULLS first;}
    # puts sql
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['count']} titoli)"
      res << [label,r['key']]
    end
    res
  end

  def SbctTitle.created_or_updated_by_select
    sql=%Q{select u.id as key, u.email as label from sbct_acquisti.titoli t join public.users u on(u.id in (t.created_by,t.updated_by))
        where t.created_by is not null or t.updated_by is not null
        group by u.id,u.email order by u.email;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']}"
      res << [label,r['key']]
    end
    res
  end

  def SbctTitle.created_by_select
    sql=%Q{select u.id as key, u.email as label from sbct_acquisti.titoli t join public.users u on(u.id = t.created_by)
        where t.created_by is not null
        group by u.id,u.email order by u.email;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']}"
      res << [label,r['key']]
    end
    res
  end
  
  def SbctTitle.pdf_per_assegnazione_copie(records)
    begin
      lp=LatexPrint::PDF.new('sbct_assegnazioni_copie', records)
      lp.makepdf
    rescue
      raise "Errore da SbctTitle.pdf_per_assegnazione_copie: #{$!} su #{records.size} records"
    end
  end
  
  def SbctTitle.options_for_select(attr)
    sql=%Q{select distinct #{attr} as dt from #{self.table_name} where #{attr} is not null order by #{attr}}
    self.connection.execute(sql).to_a.collect {|x| [x['dt'],x['dt']]}
  end

  def SbctTitle.lista_duplicati(params={})
    sql=%Q{select ean,prezzo,array_to_string(array_agg(id_titolo order by id_titolo desc), ' ') as ids from sbct_acquisti.titoli
         where ean is not null and prezzo is not null
          group by ean,lower(titolo),lower(autore),prezzo having count(*)=2}
    sql=%Q{select ean,lower(autore) as autore, lower(titolo) as titolo from sbct_acquisti.titoli
     where ean is not null and prezzo is not null
        group by ean,lower(autore),lower(titolo),prezzo having count(*)>1
	order by lower(titolo)}
    sql=%Q{select ean, array_to_string(array_agg(autore), '|') as autore,
       array_to_string(array_agg(titolo), '|')        as titolo from sbct_acquisti.titoli
     where ean is not null 
        -- and prezzo is not null
        group by ean having count(*)=2
	}

    SbctTitle.paginate_by_sql(sql, page:params[:page])
  end

  def SbctTitle.user_roles(user)
    user.roles.collect{|r| r.name if r.name =~ /Acquisition/}.compact
  end

  def SbctTitle.update_publication_year(id=nil)
    cond = id.nil? ? '' : "and id_titolo=#{id}"
    self.connection.execute("update sbct_acquisti.titoli set anno=date_part('year',datapubblicazione) where datapubblicazione is not null and anno is null #{cond}")
  end

  def SbctTitle.sql_for_tutti(params,current_user=nil)
    execsql=false

    #if current_user.id==1
    #  puts params[:sbct_event]
    #  return
    #end

    sql_comment=[]
    if params[:sbct_title].blank?
      sbct_title = SbctTitle.new()
    else
      if !params[:sbct_title][:created_by].blank?
        params[:sbct_title].delete(:created_by)
        created_by=params[:sbct_title][:created_by].to_s
        sbct_title = SbctTitle.new(params[:sbct_title])
        sbct_title.created_by=created_by
      else
        sbct_title = SbctTitle.new(params[:sbct_title])
      end
    end

    sbct_title.sottoreparto='' if sbct_title.reparto.blank?
    sbct_title.split_query

    # clavis_libraries=current_user.clavis_libraries

    sbct_budgets = current_user.nil? ? [] : current_user.sbct_budgets

    if !params[:id_lista].blank?
      sql_comment << "-- #{__FILE__} #{__LINE__} -  params[:id_lista]: #{params[:id_lista]}"    
      sbct_list = SbctList.find(params[:id_lista])
    end

    join_suppliers = ''
    if !params[:budget_id].blank?
      sbct_budget = SbctBudget.find(params[:budget_id])
    end
    
    attrib=sbct_title.attributes.collect {|a| a if not a.last.blank?}.compact
    toskip=["id_titolo"]
    attrib.delete_if do |r|
      toskip.include?(r.first)
    end
    cond=[]
    # sbct_titles = SbctTitle.paginate_by_sql("SELECT * FROM #{SbctTitle.table_name} WHERE false", :page=>1);
    attrib.each do |a|
      name,value=a
      case name
      when 'titolo'
        ts=SbctTitle.connection.quote_string(value)
        cond << %Q{#{SbctTitle.fulltext_attributes('t.')} @@ plainto_tsquery('simple', '#{ts}')}
        # cond << %Q{#{SbctTitle.fulltext_attributes('t.')} @@ plainto_tsquery('italian', '#{ts}')}
      when 'wrk'
        ts=SbctTitle.connection.quote(value)
        cond << "#{name} = #{ts}"
      when 'anno'
        if value==0
          cond << "anno is null"
        else
          cond << "#{name} = #{value.to_i}"
        end
      when 'datapubblicazione'
        cond << "#{name} = #{SbctTitle.connection.quote(value)}"
      when 'def'
        ts=SbctTitle.connection.quote(value)
        cond << "#{name} = #{ts}"
      when 'manifestation_id'
        cond << "manifestation_id = #{value.to_i}"
      when 'ean'
        if value=='null'
          cond << "ean is null"
        else
          ts=SbctTitle.connection.quote(value)
          cond << "#{name} = #{ts}"
        end
      when 'reparto','sottoreparto'
        if value=='null'
          cond << "t.#{name} is null"
        else
          ts=SbctTitle.connection.quote(value)
          cond << "t.#{name} = #{ts}"
        end
      when 'crold_notes'
        # Convoglia l'informazione sul prezzo (vedi SbctTitle.split_query)
        prezzo = attrib.select {|e| e.first=='crold_notes'}.first[1]
        prezzo.gsub!(',','.')
        min,max = prezzo.split('-')
        if max.nil?
          if min=='null'
            cond << "t.prezzo is null"
          else
            cond << "t.prezzo = #{min.to_f}"
          end
        else
          cond << "t.prezzo between #{min.to_f} and #{max.to_f}"
        end
      else
        ts=SbctTitle.connection.quote_string(value)
        cond << "t.#{name} ~* '#{ts}'"
      end
    end
    if !sbct_title.fornitore.blank?
      join_suppliers = "JOIN sbct_acquisti.suppliers suppl USING(supplier_id)"
      cond << "suppl.supplier_name ~* #{sbct_title.connection.quote(sbct_title.fornitore)}"
    end
    
    cond << "l.id_tipo_titolo = '#{params[:tipo_titolo]}'" if !params[:tipo_titolo].blank?
    # cond << "tl.id_lista = '#{params[:id_lista]}'" if !params[:id_lista].blank?
    # cond << "#{params[:created_or_updated_by]} in (t.created_by,t.updated_by)" if !params[:created_or_updated_by].blank?
    cond << "#{params[:created_by]} = t.created_by" if !params[:created_by].blank?

    cond << "t.ean in(select ean from sbct_acquisti.titoli where ean is not null group by ean having count(ean)>1)" if !params[:ean_dupl].blank?
    
    if sbct_title.age.to_i > 0
      cond << "t.datapubblicazione between now() - interval '#{sbct_title.age.to_i} days' and now()"
    end

    if sbct_title.datains.to_i > 0
      cond << "t.date_created between now() - interval '#{sbct_title.datains.to_i} days' and now()"
    end

    if sbct_title.clavis_library_ids.blank?
      join_type_libraries = 'LEFT'
    else
      join_type_libraries = ''
      execsql=true
      cond << "cp.library_id IN (#{sbct_title.clavis_library_ids.join(',')})"
    end
    # join_type_libraries = '' if !params[:con_copie].blank?
    join_type_libraries = '' if params[:copie] == 'y'
    # if !params[:senza_copie].blank?
    if params[:copie] == 'n'
      join_type_libraries = 'LEFT'
      cond << "cp is null"
    end

    cond << "cp.qb" if params[:qb_select] == 'S'
    if params[:qb_select] == 'N'
      cond << "cp.qb = false"
      cond << "(cp.order_id is not null or cp.order_status='S')"
    end

    if params[:original_filename].blank?
      join_imptit = ''
    else
      join_imptit = 'JOIN sbct_acquisti.import_titoli imptit using(id_titolo)'
      cond << "imptit.original_filename=#{self.connection.quote(params[:original_filename])}"
    end

    join_l_titoli_liste = join_lists = ''
    if !sbct_list.nil? or not params[:tipo_titolo].blank?
      join_lists = 'JOIN sbct_acquisti.liste l using(id_lista)'
      join_l_titoli_liste = "left join sbct_acquisti.l_titoli_liste tl using(id_titolo)"
      join_l_titoli_liste = "join sbct_acquisti.l_titoli_liste tl using(id_titolo)"
      # cond << "l.id_lista = #{sbct_list.id}" if params[:tipo_titolo].blank?
      # cond << "-- commento"
      if params[:norecurs].blank?
        list_ids=''
        (
          l=SbctList.new
          l.id_lista=sbct_list.id
          list_ids=l.descendants.collect {|x| x['descendant_id'].to_i}.join(',')
        )
        sql_comment << "-- #{__FILE__} #{__LINE__} - list ids: #{list_ids}"
        # cond << "l.id_lista in(select id_lista from sbct_acquisti.liste where parent_id=#{sbct_list.id} or id_lista=#{sbct_list.id})"
        cond << "l.id_lista in(#{list_ids})"
      else
        cond << "l.id_lista = #{sbct_list.id}"
      end
    end
    if sbct_title.inliste == 'n'
      join_l_titoli_liste = "left join sbct_acquisti.l_titoli_liste tl using(id_titolo)"
      cond << "tl is null"
    end
    if sbct_title.inliste == 'y'
      join_l_titoli_liste = "join sbct_acquisti.l_titoli_liste tl using(id_titolo)"
    end
    if sbct_title.inliste == 'nodatains'
      join_l_titoli_liste = "join sbct_acquisti.l_titoli_liste tl using(id_titolo)"
      cond << " tl.date_created is null" ; # cioè, senza data di inserimento in lista
    end
    
    join_budgets = ''
    if !sbct_budget.nil?
      # if !params[:con_copie].blank?
      if params[:copie] == 'y'
        join_budgets = 'LEFT JOIN sbct_acquisti.budgets b on(b.budget_id=cp.budget_id)'
        cond << "b.budget_id = #{sbct_budget.id}"
      else
        cond << "cp.id_titolo in (select id_titolo from sbct_acquisti.copie where budget_id=#{sbct_budget.id})"
      end
    end
    if !sbct_title.budget.blank?
      if sbct_title.budget=='null'
        cond << "cp.budget_id is null"
      else
        join_budgets = 'JOIN sbct_acquisti.budgets b on(b.budget_id=cp.budget_id)'
        cond << "b.label ~* #{sbct_title.connection.quote(sbct_title.budget)}"
      end
    end

    # params[:pproposal] = true if params[:order]=='10'
    
    if params[:pproposal].blank?
      select_pproposal = join_pproposal = group_pproposal = ''
    else
      execsql = true
      select_pproposal = "array_to_string(array_agg(distinct pp.proposal_id order by pp.proposal_id desc),',') as proposal_ids,"
      group_pproposal = ""
      # A - in attesa
      # B - accettata
      # C - rifiutata
      # D - annullata dall'utente
      # E - soddisfatta
      join_pproposal = "JOIN sbct_acquisti.l_clavis_purchase_proposals_titles lppt ON (lppt.id_titolo=t.id_titolo) JOIN clavis.purchase_proposal pp using(proposal_id)"
      cond << "pp.status in ('A','B','C','E')"
    end

    if params[:reserv].blank?
      select_reserv = join_reserv = group_reserv = ''
    else
      execsql = true
      select_reserv = "pr.reqnum,pr.available_items,"
      group_reserv = ",pr.reqnum,pr.available_items"
      join_reserv = "JOIN clavis.piurichiesti pr using(manifestation_id)"
      # join_reserv = "JOIN clavis.piurichiesti pr on(pr.manifestation_id=t.manifestation_id and cp.supplier_id in (select supplier_id from sbct_acquisti.suppliers where supplier_name ~ '^MiC'))"
      join_reserv = "JOIN clavis.piurichiesti pr on(pr.manifestation_id=t.manifestation_id)"
    end

    cond << "t.manifestation_id is not null" if params[:in_clavis]=='y'
    cond << "t.manifestation_id is null" if params[:in_clavis]=='n'

    cond << "t.manifestation_id is null" if !params[:non_in_clavis].blank?

    cond << "reparto is not  null" if !params[:con_reparto].blank?

    if params[:order_status]=='OP'
      # Ordine in preparazione (non ancora inviato)
      join_order="JOIN sbct_acquisti.orders o using (order_id)"
      cond << "not o.inviato"
    else
      join_order=''
      if params[:order_status]=='I'
        cond << "cp.order_status IS NULL"
      else
        if params[:order_status]=='AO'
          cond << "cp.order_status IN ('A','O')" if !params[:order_status].blank?
        else
          cond << "cp.order_status = #{sbct_title.connection.quote(params[:order_status])}" if !params[:order_status].blank?
        end
      end
    end

    cond << "cp.order_id = #{sbct_title.connection.quote(params[:order_id])}" if !params[:order_id].blank?

    # cond << "cp.supplier_id = #{sbct_title.connection.quote(params[:supplier_id])} and cp.order_status in('A','O')" if !params[:supplier_id].blank?

    cond << "cp.supplier_id = #{sbct_title.connection.quote(params[:supplier_id])}" if !params[:supplier_id].blank?
    cond << "cp.numcopie > 1" if params[:numcopie]=='m'

    #render text:cond.inspect and return
    #render text:Time.now and return

    order_by = execsql == true ? 'order by t.autore,t.titolo' : nil

    case (params[:order])
    when '1'
      order_by = 'order by t.autore,t.titolo'
    when '2'
      order_by = 'order by t.editore,t.autore,t.titolo'
    when '3'
      order_by = 'order by t.id_titolo desc'
    when '4'
      order_by = 'order by t.prezzo,t.autore,t.titolo'
    when '5'
      # order_by = 'order by numcopie desc, library_ids'
      order_by = 'order by numcopie desc'
      cond << "numcopie is not null"
    when '6'
      order_by = 'order by t.anno desc nulls last,t.autore,t.titolo'
      # cond << "t.anno notnull"
    when '7'
      order_by = 'order by t.datapubblicazione desc nulls last,t.anno desc,t.autore,t.titolo'
      # cond << "t.datapubblicazione notnull"
    when '8'
      order_by = 'order by random()'
    when '9'
      order_by = 'order by t.titolo'
    when '10'
      params[:copie_clavis] = 'S'
      order_by = 'order by num_copie_in_clavis desc'
    when '11'
      # order_by = 'order by cp.created_at'
    when ''
      #if group_pproposal.blank?
      #  order_by = ''
      #else
      #  order_by = 'order by pp.proposal_date desc, t.titolo' 
      #end
    end
    order_by = "order by t.id_titolo desc" if order_by.blank? and !params[:ean_dupl].blank?

    if params[:copie_clavis].blank?
      select_copie_clavis = join_copie_clavis = ''
    else
      execsql = true
      select_copie_clavis = "array_to_string(array_agg(distinct items.cnt),',')::integer as num_copie_in_clavis,"
      join_copie_clavis = %Q{LEFT JOIN LATERAL (SELECT count(item_id) as cnt
       FROM clavis.item ci JOIN sbct_acquisti.library_codes alc on (alc.clavis_library_id=ci.home_library_id)
   WHERE manifestation_id=t.manifestation_id and item_status!='E' and owner_library_id>0 limit 1) as items on true}
    end

    if params[:sbct_event].blank?
      select_event = join_event = group_event = ''
    else
      execsql = true
      select_event = ''
      join_event = "JOIN sbct_acquisti.l_events_titles evt on (evt.id_titolo=t.id_titolo)"
      group_event = ''
      cond << "evt.event_id=#{params[:sbct_event].to_i}"
    end

    if params[:dnoteid].blank?
      select_dnotes = join_dnotes = ''
    else
      execsql = true
      select_dnotes = ''
      join_dnotes = "JOIN sbct_acquisti.report_logistico rlog on (rlog.id_titolo=t.id_titolo)"
      delivery_date,delivery_note = params[:dnoteid].split('|')
      cond << "rlog.datainviomerce=#{self.connection.quote(delivery_date)} AND rlog.numerobollaconsegna=#{delivery_note.to_i}"
    end
    
    cond = cond.join(" AND ")

    cond = execsql.to_s if cond.blank?
    cond = "WHERE #{cond}" 

    if !sbct_title.titolo.nil? and sbct_title.titolo.split.size==1
      cond = "WHERE id_titolo=#{sbct_title.titolo.to_i}" if sbct_title.titolo.to_i > 0 and sbct_title.titolo.size<10
    end
    
    per_page = params[:per_page].blank? ? 200 : params[:per_page]

    # array_length(array_agg(cp.library_id),1) as numcopie,
    
    if join_l_titoli_liste.blank?
      select_titoli_liste = 'NULL as data_ins_in_lista,'
    else
      select_titoli_liste = "array_to_string(array_agg(distinct tl.date_created::date order by tl.date_created::date desc), ',') as data_ins_in_lista,"
    end
      
    sql=%Q{
#{sql_comment.join("\n")}
select t.id_titolo,t.collana,t.autore,t.titolo,t.editore,t.manifestation_id,t.prezzo,t.target_lettura,t.isbn,t.anno,t.reparto,t.datapubblicazione,t.note,#{select_pproposal}#{select_reserv}
-- array_to_string(array_agg(concat_ws('-',lcod.label,cp.numcopie, (case when cp.order_status is null then 'I' else cp.order_status end)) order by lcod.label),',') as infocopie,
-- array_to_string(array_agg(distinct cp.library_id),',') as library_ids,
-- array_to_string(array_agg(distinct lcod.label order by lcod.label),',') as library_codes,
#{select_copie_clavis}
#{select_titoli_liste}
array_to_string(array_agg(distinct copie.lbl),',') as infocopie,
sum(cp.numcopie) as numcopie,
t.date_created,t.date_updated
 from sbct_acquisti.titoli t
 #{join_l_titoli_liste}
 #{join_lists}
 #{join_type_libraries} join sbct_acquisti.copie cp using(id_titolo)
 #{join_type_libraries} join sbct_acquisti.library_codes lcod on (lcod.clavis_library_id = cp.library_id)
 #{join_pproposal}
 #{join_copie_clavis}

 LEFT JOIN LATERAL (SELECT concat_ws('-',alc2.label,1, case when xcp.order_status is null then 'I' else xcp.order_status end) as lbl
       FROM sbct_acquisti.copie xcp JOIN sbct_acquisti.library_codes alc2 on (alc2.clavis_library_id=xcp.library_id)
   WHERE id_titolo=t.id_titolo) as copie on true

 #{join_reserv}
 #{join_budgets}
 #{join_order}
 #{join_suppliers}#{join_event}#{join_dnotes}#{join_imptit}
      #{cond}
     group by t.id_titolo,t.autore,t.titolo,t.editore,t.manifestation_id,t.prezzo,t.target_lettura,t.isbn,t.anno,t.datapubblicazione#{group_pproposal}#{group_reserv}
    #{order_by}
    }

    if !current_user.nil? and current_user.email=='seba'
      fd=File.open("/home/seb/sbct_titles.sql", "w")
      fd.write(sql)
      fd.close
    end

    # puts sql
    [sql,sbct_title,sbct_list,sbct_budgets,sbct_budget]
  end

  def SbctTitle.is_ean?(str)
    (!str.blank? and [10,13].include?(str.size) and (str =~ /^\d{9}/)==0) ? true : false
  end

  def SbctTitle.import_from_csv(csvfilename,target_table,create_table=false,truncate_table=true)
    csv = CSV.read(csvfilename)
    header = csv.shift

    columns = []
    cols=[]
    header.each do |r|
      columns << "#{r.downcase} text"
      cols << "#{r.downcase}"
    end
    sql=[]
    sql << "CREATE TABLE IF NOT EXISTS #{target_table} (#{columns.join(",\n")});" if create_table
    sql << "TRUNCATE #{target_table};" if truncate_table
    sql << "COPY #{target_table}(#{cols.join(",")}) FROM STDIN;"
    csv.each do |r|
      x = r.map.each {|c| c.blank? ? "\\N" : c}
      sql << x.join("\t")
    end
    sql << "\\.\n"
    sql.join("\n")
  end

  def SbctTitle.delivery_notes_select(params={},user=nil)
    sql = %Q{select cliente,datainviomerce as delivery_date,numerobollaconsegna as delivery_note,count(numerobollaconsegna)
       from sbct_acquisti.report_logistico where numerobollaconsegna is not null
    group by cliente,datainviomerce,numerobollaconsegna order by datainviomerce desc,numerobollaconsegna desc;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['delivery_date'].to_date} - #{r['delivery_note']} #{r['cliente']} (#{r['count']} titoli)"
      res << [label,"#{r['delivery_date']}|#{r['delivery_note']}"]
    end
    res
  end

  def SbctTitle.associa_ean_con_manifestation_id(ean, manifestation_id)
    sql=%Q{
      UPDATE sbct_acquisti.titoli set manifestation_id=#{manifestation_id.to_i}
          WHERE id_titolo = (
        SELECT id_titolo from sbct_acquisti.titoli where ean=#{self.connection.quote(ean)}
          group by id_titolo HAVING count(*) = 1
       )
       and manifestation_id is null
    }
    res = self.connection.execute(sql)
    if res.cmd_tuples==1
      sql=%Q{SELECT id_titolo from sbct_acquisti.titoli where ean=#{self.connection.quote(ean)}
          group by id_titolo HAVING count(*) = 1}
      self.connection.execute(sql).first['id_titolo']
    else
      nil
    end
  end

  def SbctTitle.cancella_titoli_con_data_di_pubblicazione_futura(giorni_nel_futuro=90,id_lista=nil)
    raise "giorni_nel_futuro deve essere positivo, non #{giorni_nel_futuro}" if giorni_nel_futuro.to_i < 1
    id_lista = id_lista.to_i
    if id_lista==0
      cond_list = ''
      exclude_list = "and t.id_titolo not in (select id_titolo from sbct_acquisti.l_titoli_liste)"
    else
      ids=SbctList.find(id_lista).descendants_ids
      cond_list = "and tl.id_lista IN (#{ids})"
      # exclude_list = "and t.id_titolo not in (select id_titolo from sbct_acquisti.l_titoli_liste where id_lista!=#{id_lista})"
      exclude_list = "and t.id_titolo not in (select id_titolo from sbct_acquisti.l_titoli_liste where id_lista not in (#{ids}))"
    end
    sql=%Q{
BEGIN;
ALTER TABLE sbct_acquisti.titoli DISABLE TRIGGER sbct_acquisti_list_update;
with t1 as
(select t.*,cp.id_copia from sbct_acquisti.titoli t join sbct_acquisti.l_titoli_liste tl using(id_titolo)
  left join sbct_acquisti.copie cp on(cp.id_titolo=t.id_titolo)
  where cp.id_copia is null #{cond_list}
  and t.created_by is null
  and t.datapubblicazione > now() + interval '#{giorni_nel_futuro} days'
  #{exclude_list}
)
delete from sbct_acquisti.titoli where id_titolo in (select id_titolo from t1);
ALTER TABLE sbct_acquisti.titoli ENABLE TRIGGER sbct_acquisti_list_update;
COMMIT;
}
    self.connection.execute(sql)
    # return sql
  end

  def SbctTitle.params_to_human(prms)
    res = []
    skip = ['utf8', 'commit', 'action', 'controller']
    prms.each_pair do |k,v|
      next if skip.include?(k) or v.blank?
      if v.class!=String
        v.each_pair do |k1,v1|
          res << "#{k1}: #{v1}" if !v1.blank?
        end
      else
        res << "#{k}: #{v}"
      end
    end
    res.join(', ')
  end
  
end
