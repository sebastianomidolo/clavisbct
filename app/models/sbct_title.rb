# coding: utf-8
class SbctTitle < ActiveRecord::Base

  self.table_name='sbct_acquisti.titoli'
  self.primary_key = 'id_titolo'

  before_save :add_timestamp

  attr_accessible :id_titolo, :manifestation_id, :titolo, :autore, :editore, :collana, :prezzo, :utente, :id_tipo_titolo, :isbn, :wrk, :def, :clavis_library_ids, :sbct_list_ids, :ean, :target_lettura, :reparto, :sottoreparto

  validates :titolo, presence: true

  belongs_to :sbct_tipo_titolo, :foreign_key=>'id_tipo_titolo'
  has_and_belongs_to_many(:sbct_lists, join_table:'sbct_acquisti.l_titoli_liste',
                          :foreign_key=>'id_titolo',
                          :association_foreign_key=>'id_lista')

  has_and_belongs_to_many(:clavis_libraries, join_table:'sbct_acquisti.copie',
                          :foreign_key=>'id_titolo',
                          :association_foreign_key=>'library_id')

  # has_many :sbct_items, :foreign_key=>'id_titolo', include:[:sbct_budget]
  def sbct_items
    sql = %Q{select cp.*,lc.label as siglabib from sbct_acquisti.copie cp
        join clavis.library cl on(cl.library_id=cp.library_id)
        join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
         where id_titolo=#{self.id} order by lc.label;}
    SbctItem.find_by_sql(sql)
  end

  def copie
    []
  end

  def elimina_duplicato(dup_id)
    # puts "elimino duplicato #{dup_id} portando le sue copie su #{self.id}"
    sql = %Q{update sbct_acquisti.copie set id_titolo = #{self.id} where id_titolo = #{dup_id}; delete from sbct_acquisti.titoli where id_titolo=#{dup_id};}
    # sql = %Q{update sbct_acquisti.copie set id_titolo = #{self.id} where id_titolo = #{dup_id};}
    puts sql
    self.connection.execute(sql)
  end

  def tipo_titolo_to_label
    return nil if self.id_tipo_titolo.nil?
    self.connection.execute("select tipo_titolo as t from sbct_acquisti.tipi_titolo where id_tipo_titolo='#{self.id_tipo_titolo}'").first['t']
  end

  def clavis_patrons
    sql=%Q{select l.*,al.data_richiesta_lettore,al.id_acquisti,cp.lastname,cp.name,cp.patron_id,cp.barcode
              from cr_acquisti.acquisti_lettore al join cr_acquisti.t_lettore l on (l.idlettore=al.id_lettore)
           left join clavis.patron cp on (lower(cp.barcode)=lower(l.cognome)) where id_acquisti = #{self.id};}
    puts sql
    self.connection.execute(sql).to_a
  end

  def add_timestamp
    if self.date_created.nil?
      self.date_created = Time.now
    else
      self.date_updated = Time.now
    end
    self.manifestation_id = get_manifestation_id_from_isbn(self.ean) if (self.manifestation_id.nil? && !self.ean.blank?)
    true
  end
  
  def get_manifestation_id_from_isbn(isbn)
    sql=%Q{select manifestation_id as id from clavis.manifestation where "ISBNISSN" = #{self.connection.quote(isbn)}}
    # raise sql
    r=self.connection.execute(sql).to_a.first
    r.nil? ? nil : r['id'].to_i
  end

  def esemplari_presenti_in_clavis
    sql=%Q{select distinct ci.item_id,ci.home_library_id,cl.label,status.value_label as item_status,
            ci.inventory_date, ci.inventory_serie_id || '-' || ci.inventory_number as serieinv from sbct_acquisti.copie c join sbct_acquisti.titoli t
        using(id_titolo) join clavis.item ci using(manifestation_id) join
         clavis.library cl on(cl.library_id = ci.home_library_id) join
        clavis.lookup_value status on(status.value_key=ci.item_status and
        status.value_language = 'it_IT' and status.value_class =
        'ITEMSTATUS') where t.id_titolo = #{self.id} order by cl.label;}
    puts sql
    self.connection.execute(sql).to_a
  end

  def siglebct
    self.sbct_items.collect {|i| ClavisLibrary.siglabct(i.library_id)}.sort.join(', ')
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
         to_tsvector('simple', coalesce(utente, ''))
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
  

  def self.libraries_select
    sql=%Q{select library_id as key,lc.label || ' (' || substr(cl.label,6) || ')' as label
         from sbct_acquisti.library_codes lc join clavis.library cl on(cl.library_id=lc.clavis_library_id) where library_internal='1' order by lc.label;}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

  def SbctTitle.import_mdb(mdbfile)
    include AccessImport
    puts "In SbctTitle.import_mdb #{mdbfile}"
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
         alter table cr_acquisti.acquisti rename COLUMN g to gin;
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
     select u.id,cl.name,cl.lastname,cl.username,
             array_to_string(array_agg(r.name order by r.name),', ') as role_names,
             array_to_string(array_agg(ru.role_id order by ru.role_id),', ') as this_user_roles
       from public.roles_users ru join public.users u on (u.id=ru.user_id) join public.roles r on(r.id=ru.role_id)
        join clavis.librarian cl on(cl.username=u.email) 
         where ru.role_id in( 46, 47, 48) 
        group by u.id,cl.name,cl.lastname,cl.username
        order by cl.lastname;
   }
    User.find_by_sql(sql)
  end

  def SbctTitle.target_lettura_select(params={})
    join_cond = params[:id_lista].blank? ? 'WHERE' : "JOIN sbct_acquisti.l_titoli_liste USING(id_titolo) WHERE id_lista=#{self.connection.quote(params[:id_lista])} AND"
    sql=%Q{select target_lettura as key,target_lettura as label, count(*) from sbct_acquisti.titoli #{join_cond} target_lettura notnull group by target_lettura order by target_lettura;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['count']} titoli)"
      res << [label,r['key']]
    end
    res
  end

  def SbctTitle.reparto_select(params={})
    join_cond = params[:id_lista].blank? ? 'WHERE' : "JOIN sbct_acquisti.l_titoli_liste USING(id_titolo) WHERE id_lista=#{self.connection.quote(params[:id_lista])} AND"
    sql=%Q{select reparto as key, reparto as label, count(*) from sbct_acquisti.titoli #{join_cond} reparto notnull group by reparto order by reparto;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['count']} titoli)"
      res << [label,r['key']]
    end
    res
  end

  def SbctTitle.sottoreparto_select(params={})
    join_cond = params[:id_lista].blank? ? 'WHERE' : "JOIN sbct_acquisti.l_titoli_liste USING(id_titolo) WHERE id_lista=#{self.connection.quote(params[:id_lista])} AND"
    sql=%Q{select sottoreparto as key, concat('(', reparto, ') - ', sottoreparto) as label, count(*) from sbct_acquisti.titoli #{join_cond} reparto notnull and sottoreparto notnull group by reparto,sottoreparto order by reparto, sottoreparto NULLS first;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['count']} titoli)"
      res << [label,r['key']]
    end
    res
  end

  
  def SbctTitle.elimina_duplicati
    sql=%Q{select ean,prezzo,array_to_string(array_agg(id_titolo order by id_titolo desc), ' ') as ids from sbct_acquisti.titoli
         where ean is not null and prezzo is not null
          group by ean,lower(titolo),lower(autore),prezzo having count(*)=2}
    self.connection.execute(sql).to_a.each do |r|
      a,b = r['ids'].split
      # puts "ean: #{r['ean']} - ids: #{r['ids']} (a: #{a} - b: #{b})"
      SbctTitle.find(a).elimina_duplicato(b)
    end
    
  end

  
end
