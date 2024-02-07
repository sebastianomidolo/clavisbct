# coding: utf-8
class SbctList < ActiveRecord::Base

  self.table_name='sbct_acquisti.liste'

  attr_accessible :id_tipo_titolo, :label, :budget_label, :locked, :parent_id, :default_list, :owner_id, :hidden, :allow_uploads, :library_id, :protected,
                  :from_clavis_shelf_id, :update_rules
  before_save :check_record

  has_and_belongs_to_many(:sbct_titles, join_table:'sbct_acquisti.l_titoli_liste',
                          :foreign_key=>'id_lista',
                          :association_foreign_key=>'id_titolo')
  belongs_to :parent, class_name:'SbctList'
  has_many :children, class_name:'SbctList', primary_key:'id_lista', foreign_key:'parent_id'
  belongs_to :sbct_user, foreign_key:'owner_id'
  belongs_to :clavis_library, foreign_key:'library_id'
  validates :label, presence: true
  attr_accessor :from_clavis_shelf_id

  def to_label
    if self.label.blank?
      "#{self.data_libri} #{self.label} tipo #{self.id_tipo_titolo}"
    else
      "#{self.label} (#{self.locked? ? 'chiusa' : 'aperta'})"
      self.label
    end
  end

  def auto_insert
    return if self.update_rules.blank?
    d = self.update_rules.gsub(/\n|\r/, '').split(';')
    sql = "INSERT INTO sbct_acquisti.l_titoli_liste(id_lista, id_titolo) (select #{self.id},#{d[0]} FROM #{d[1]} WHERE #{d[2]}) ON CONFLICT DO NOTHING;"
    self.connection.execute(sql)
  end

  def owner_to_label
    self.sbct_user.nil? ? '[nessuno]' : self.sbct_user.to_label
  end
  def owned_by(user)
    return false if self.sbct_user.nil?
    user_id = user.class==User ? user.id : User.find(user).id
    self.owner_id==user_id
  end

  def check_record

    
  end
  
  def ricalcola_prezzi_con_sconto
    sql = %Q{
with t1 as (select cp.id_copia,t.prezzo as prezzo_titolo,cp.prezzo as prezzo_copia,	
         case when cs.discount is null then 0 else cs.discount end as sconto
    FROM sbct_acquisti.copie cp join sbct_acquisti.titoli t using(id_titolo)
       JOIN sbct_acquisti.l_titoli_liste tl using(id_titolo)
       JOIN sbct_acquisti.liste l on(l.id_lista = tl.id_lista)
       JOIN clavis.budget cb on(cb.budget_title = l.budget_label)
       JOIN clavis.supplier cs using(supplier_id)
       WHERE l.id_lista = #{self.id} and cp.budget_id is not null )
-- select t1.prezzo_titolo - (t1.sconto*t1.prezzo_titolo)/100 as prezzo_scontato from t1 order by t1.id_copia
UPDATE sbct_acquisti.copie c set prezzo = t1.prezzo_titolo - (t1.sconto*t1.prezzo_titolo)/100 from t1 where t1.id_copia=c.id_copia
    }
    fd=File.open("/home/seb/ricalcola_prezzi.sql", "w")
    fd.write(sql)
    fd.close
    # self.connection.execute(sql)    
  end

  def import_titles_from_clavis_shelf(shelf_id, user=nil)
    return if shelf_id.nil?
    cnt = self.connection.execute("select count(*) from clavis.shelf_item where shelf_id = #{shelf_id.to_i}").first['count'].to_i
    puts "shelf id #{shelf_id} - contiene #{cnt}"
    r=ClavisShelf.soap_get_records_in_shelf(shelf_id)
    #return r
    cnt = self.connection.execute("select count(*) from clavis.shelf_item where shelf_id = #{shelf_id.to_i}").first['count'].to_i
    puts "shelf id #{shelf_id} - contiene #{cnt} manifestations"
    if user.nil?
      user = User.find_by_email('system')
    end
    ClavisManifestation.in_shelf(shelf_id).each do |rec|
      ean  = rec.EAN.blank? ? '' : rec.EAN.strip
      isbn = rec.ISBNISSN.blank? ? '' : rec.ISBNISSN.strip
      puts "Vedo se inserire in PAC titolo ean:#{ean} - isbn:#{isbn} con manifestation_id #{rec.manifestation_id}"
      p = SbctTitle.find_by_manifestation_id(rec.manifestation_id)
      if p.nil?
        t=SbctTitle.new(titolo:rec['title'],
                        autore:rec['author'],
                        editore:rec['publisher'],
                        ean:rec['EAN'],
                        isbn:rec['ISBNISSN'],
                        anno:rec['edition_date'],
                        manifestation_id:rec['manifestation_id'],
                        note:"Titolo importato da Clavis da scaffale #{shelf_id} - #{Time.now.to_date}"
                       )
        t.date_created=Time.now
        t.created_by = user.id
        t.save
        t.reload
        id_titolo=t.id
      else
        id_titolo=p.id
        puts "questo c'è già in pac, id_titolo: #{p.id}"
      end
      sql = "INSERT INTO sbct_acquisti.l_titoli_liste(id_lista,id_titolo,created_by) values(#{self.id},#{id_titolo},#{user.id}) ON CONFLICT(id_lista,id_titolo) do nothing;"
      puts sql
      self.connection.execute(sql)
    end
    nil
  end

  
  def assegna_fornitore
    if self.budget_label.blank?
      puts "Questa lista non è associata a nessun budget e non è possibile dunque associare un fornitore"
      return
    end
    budget = self.budget(1)
    if budget.nil?
      puts "Questa lista è associata a budget multi-fornitore (#{self.budget_label}) per cui non è automatico associare il fornitore"
      return
    else
      if budget.sbct_supplier.nil?
        puts "budget #{budget.to_label} non ha un fornitore associato"
        return
      end
    end
    puts %Q{Lista #{self.to_label} con id #{self.id} e budget "#{budget.to_label}",  fornitore da assegnare alle copie che ancora ne sono prive:  "#{budget.sbct_supplier.to_label}"}
    sql = %Q{with t1 as (select cp.id_copia,cp.supplier_id,b.supplier_id as new_supplier_id
          FROM sbct_acquisti.copie cp join sbct_acquisti.titoli t using(id_titolo)
                 JOIN sbct_acquisti.l_titoli_liste tl using(id_titolo)
                 JOIN sbct_acquisti.liste l on(l.id_lista = tl.id_lista)
                 JOIN clavis.budget cb on(cb.budget_title = l.budget_label)
                 JOIN sbct_acquisti.budgets b on(b.clavis_budget_id = cb.budget_id and b.budget_id = cp.budget_id)
                 WHERE l.id_lista = #{self.id} and cp.budget_id is not null
       -- and cp.supplier_id is null
)
            UPDATE sbct_acquisti.copie c set supplier_id = t1.new_supplier_id from t1 where t1.id_copia = c.id_copia;}
    puts sql
    self.connection.execute(sql)
  end

  def sbct_titles_con_ean_non_univoco
    sql = %Q{
        select ean,autore,titolo from sbct_acquisti.titoli where ean in
         (select ean from sbct_acquisti.import_titoli where id_lista=#{self.id}
          group by ean having count(*)>1)}
    SbctTitle.find_by_sql(sql)
  end
  def sbct_titles_senza_ean
    sql = %Q{select * from sbct_acquisti.import_titoli where id_lista = #{self.id} and ean is null;}
    SbctTitle.find_by_sql(sql)
  end

  def remove_all_titles
    self.connection.execute "DELETE FROM sbct_acquisti.l_titoli_liste Where id_lista IN (#{self.descendants_ids})"
  end

  def budget(library_id)
    b=self.clavis_budgets
    return nil if b.size==0
    library_ids=b['library_ids'].split(',')
    library_id = library_ids.first if library_ids.size==1 and library_ids.first.to_i==1
    i = library_ids.find_index(library_id.to_s)
    return nil if i.nil?
    budget_id=b['budget_ids'].split(',')[i].to_i
    SbctBudget.find(budget_id)
  end

  def clavis_budgets
    return [] if self.budget_label.blank?
    sql = SbctList.sql_for_clavis_label_select(self.budget_label)
    self.connection.execute(sql).to_a.first
  end

  # Assegna alle copie che non ne siano ancora provviste il budget associato a questa lista
  # e il fornitore associato al budget
  def budget_assign
    sql = sql_for_budget_assign
    return nil if sql.blank?
    # puts "Assegno budget #{self.budget_label}"
    # puts sql
    # self.connection.execute(sql)
    sql
  end

  def sql_for_budget_assign
    return '' if self.budget_label.nil?
    %Q{UPDATE sbct_acquisti.copie cp
    SET
     order_status = 'S',
     budget_id = t1.budget_id,
     supplier_id = t1.supplier_id
    FROM
      (
       SELECT b.budget_id, b.supplier_id,l.id_lista,tl.id_titolo
         FROM
	   sbct_acquisti.liste l JOIN
	   clavis.budget cb ON(cb.budget_title=l.budget_label) JOIN
	   sbct_acquisti.budgets b ON(b.clavis_budget_id=cb.budget_id) JOIN
           sbct_acquisti.l_titoli_liste tl USING(id_lista)
	 WHERE 
 	   l.id_lista=#{self.id} AND cb.library_id=1
       ) as t1
      WHERE t1.id_titolo=cp.id_titolo AND cp.budget_id is null
    }
  end

  def sql_for_budgets_assign_old
    return '' if self.budget_label.nil?
    %Q{with lecopie as   (
     select l.id_lista,b.clavis_budget_id,b.budget_id,cb.library_id as clavis_budget_library_id,
       l.budget_label,tl.id_titolo,t.prezzo as prezzo_titolo, cp.id_copia  
         FROM sbct_acquisti.liste l
          JOIN sbct_acquisti.l_titoli_liste tl using(id_lista)
          JOIN sbct_acquisti.titoli t using(id_titolo)
          JOIN sbct_acquisti.copie cp using(id_titolo)
          JOIN clavis.budget cb ON (cb.budget_title=l.budget_label)
          JOIN sbct_acquisti.budgets b ON (b.clavis_budget_id = cb.budget_id)
          WHERE l.id_lista=#{self.id} AND cp.budget_id is null
           AND cb.library_id = cp.library_id)
        update sbct_acquisti.copie as cp set budget_id = lecopie.budget_id, prezzo = lecopie.prezzo_titolo
        from lecopie where cp.id_copia = lecopie.id_copia and cp.budget_id is null and cp.supplier_id is null;
}
  end

  def conta_titoli
    self.connection.execute("SELECT count(id_titolo) FROM sbct_acquisti.l_titoli_liste WHERE id_lista in (#{self.descendants_ids})").first['count'].to_i
  end

  def valore_titoli
    self.connection.execute("SELECT sum(prezzo) as totale FROM sbct_acquisti.titoli t join sbct_acquisti.l_titoli_liste tl using(id_titolo) WHERE tl.id_lista in (#{self.descendants_ids})").first['totale'].to_f
  end

  def descendants_ids(include_self=true)
    if include_self
      self.descendants.collect {|x| x['descendant_id'].to_i}.join(',')
    else
      self.descendants_index.collect {|x| x['id_lista'].to_i}.join(',')
    end
  end

  def descendants
    self.connection.execute(self.sql_for_descendants).to_a
  end

  def sql_for_descendants(order_by='')
    # Esempio di order_by: "level, ancestor_id"
    order = order_by.blank? ? '' : "ORDER BY #{order_by}"
    %Q{WITH RECURSIVE descendant AS (
    SELECT  id_lista, label, parent_id, 0 AS level
        FROM sbct_acquisti.liste
         WHERE id_lista = #{self.id}
    UNION ALL
 SELECT  ft.id_lista, ft.label, ft.parent_id, level + 1
 FROM sbct_acquisti.liste ft JOIN descendant d ON ft.parent_id = d.id_lista
)

SELECT  d.id_lista AS descendant_id,
        d.label AS descendant_label,
        a.id_lista AS ancestor_id,
        a.label AS ancestor_label,
        d.level
 FROM descendant d
LEFT  JOIN sbct_acquisti.liste a ON d.parent_id = a.id_lista
 #{order}
 }
  end

  def descendants_index(current_user=nil)
    SbctList.find_by_sql(self.sql_for_descendants_index(current_user))
  end

  def sql_for_descendants_index(current_user=nil)
    cond = []
    cond << "l.root_id=#{self.id}"
    # cond << "(not hidden or owner_id=#{current_user.id})" if !current_user.nil? and current_user.email!='seba'
    cond << "(not hidden or owner_id=#{current_user.id})" if !current_user.nil?
    cond = cond.join(' and ')
    %Q{select id_lista,level,label,count(t.id_titolo) from public.pac_lists l
      left join sbct_acquisti.l_titoli_liste t using(id_lista) where #{cond}
       and l.id_lista!=l.root_id group by l.id_lista,l.level,l.label,l.order_sequence order by l.order_sequence;
    }
  end
  
  def load_data_from_excel(sourcefile, current_user, ean='')
    require 'open3'
    cmd = %Q{LANG='en_US.UTF-8' Rscript --vanilla /home/ror/clavisbct/extras/R/carica_excel.r "#{sourcefile}"}

    # return
    @stdout,@stderr,@status=Open3.capture3(cmd)
    # Kernel.system(cmd)
    # raise "<br/>status: #{@status}<br/>stderr: #{@sterr}<br/>stdout: #{@stdout}"


    csv_file = File.join(File.dirname(sourcefile), File.basename(sourcefile, '.*')) + '.csv'
    csv = CSV.read(csv_file)
    columns = csv.shift

    original_filename = File.basename(sourcefile)

    columns << 'date_created'
    columns << 'created_by'
    columns << 'id_lista'
    columns << 'original_filename'

    date_created = Time.now.to_s
    sql = []
    sql << "DELETE FROM sbct_acquisti.import_titoli WHERE original_filename = #{self.connection.quote(original_filename)}"
    sql << "DELETE FROM sbct_acquisti.import_titoli WHERE id_titolo IN (SELECT id_titolo FROM sbct_acquisti.import_titoli WHERE id_titolo NOTNULL  GROUP BY id_titolo HAVING count(*) > 1)"
    csv.each do |r|
      r << date_created
      r << current_user.id
      r << self.id
      r << original_filename
      if !ean.blank?
        fd = File.open("/home/seb/debug2.txt", "w")
        fd.write("-- Verifico presenza ean: #{ean}\n")
        fd.write("-- #{r.first} confrontare con #{ean}\n")
        fd.close
        next if r.first!=ean
      end
      values = r.collect {|d| d=='NULL' ? d : self.connection.quote(d)}
      sql << "INSERT INTO sbct_acquisti.import_titoli (#{columns.join(',')}) VALUES(#{values.join(',')})"
    end
    fd = File.open("/home/seb/debug.txt", "w")
    fd.write("-- debug info per #{current_user.email} - ean: #{ean}\n")
    fd.write(sql.join(";\n"))
    fd.close
    self.connection.execute(sql.join(";\n"))
          
    sql=%Q{
BEGIN;
ALTER TABLE sbct_acquisti.titoli DISABLE TRIGGER sbct_acquisti_list_update;
update sbct_acquisti.import_titoli as i set id_titolo=t.id_titolo from sbct_acquisti.titoli t where i.id_titolo is null and i.ean = t.ean;

update sbct_acquisti.import_titoli set anno = date_part('year', datapubblicazione) where id_lista = #{self.id} and anno is null and datapubblicazione is not null;

update sbct_acquisti.titoli t set  anno = v.anno from sbct_acquisti.import_titoli v where v.id_titolo=t.id_titolo and v.id_lista=#{self.id};

update sbct_acquisti.titoli t set titolo=v.titolo,autore=v.autore,sottoreparto=v.sottoreparto,
        prezzo = v.prezzo,editore=v.editore,
        datapubblicazione = v.datapubblicazione from sbct_acquisti.import_titoli v where v.id_titolo=t.id_titolo and v.id_lista=#{self.id};

update sbct_acquisti.titoli t set reparto=v.reparto
        from sbct_acquisti.import_titoli v where v.id_titolo=t.id_titolo and v.id_lista=#{self.id} and t.reparto is null;



insert into sbct_acquisti.titoli
             (ean,isbn,editore,autore,titolo,collana,prezzo,datapubblicazione,reparto,sottoreparto)
      (SELECT ean, ean,editore,autore,titolo,collana,prezzo,datapubblicazione,reparto,sottoreparto
         FROM sbct_acquisti.import_titoli WHERE id_titolo is null and ean is not null);


      UPDATE sbct_acquisti.import_titoli as i set id_titolo=t.id_titolo from sbct_acquisti.titoli t where i.id_titolo is null and i.ean = t.ean;
      insert into sbct_acquisti.l_titoli_liste(id_titolo,id_lista,created_by)
         (select id_titolo,id_lista,#{current_user.id} from sbct_acquisti.import_titoli where id_titolo notnull and id_lista=#{self.id}) on conflict(id_titolo,id_lista) DO NOTHING;
delete from sbct_acquisti.import_copie where id_copia is null;
with ni as
  (select l.id_lista,b.clavis_budget_id,b.budget_id,cb.library_id as clavis_budget_library_id,
  l.budget_label,it.id_titolo,it.id_ordine,it.fornitore,unnest(string_to_array(it.siglebib, ',')) as siglabct
    FROM sbct_acquisti.import_titoli it JOIN sbct_acquisti.liste l USING(id_lista)
    JOIN clavis.budget cb ON (cb.budget_title=l.budget_label)
    JOIN sbct_acquisti.budgets b ON (b.clavis_budget_id = cb.budget_id)
       WHERE it.siglebib is not null and it.id_titolo is not null and l.id_lista=#{self.id})

insert into sbct_acquisti.import_copie(id_titolo,library_id,budget_id,id_ordine,supplier_id)
 (select distinct ni.id_titolo,lc.clavis_library_id as library_id,ni.budget_id,ni.id_ordine,cs.supplier_id
     FROM ni
      join sbct_acquisti.library_codes lc on(lc.label = ni.siglabct)
      left join clavis.supplier cs on(ni.fornitore = cs.supplier_name)
      left join sbct_acquisti.copie cp on (cp.id_titolo=ni.id_titolo AND cp.library_id=lc.clavis_library_id AND cp.budget_id=ni.budget_id)
      left join sbct_acquisti.import_copie ic on (ic.id_titolo=ni.id_titolo AND ic.library_id=lc.clavis_library_id AND ic.budget_id=ni.budget_id)
         WHERE ni.clavis_budget_library_id IN(lc.clavis_library_id,1) and ic is null);


update sbct_acquisti.import_copie as ic set id_copia=c.id_copia
     from sbct_acquisti.copie c where ic.id_copia is null
         and ic.id_titolo=c.id_titolo and ic.budget_id=c.budget_id and ic.library_id=c.library_id;
	 
insert into sbct_acquisti.copie (id_titolo,budget_id,library_id,id_ordine,supplier_id)
   (select id_titolo,budget_id,library_id,id_ordine,supplier_id from sbct_acquisti.import_copie
        where id_copia is null);

-- update sbct_acquisti.import_copie as ic set id_copia=c.id_copia
--      from sbct_acquisti.copie c where ic.id_copia is null
--          and ic.id_titolo=c.id_titolo and ic.budget_id=c.budget_id and ic.library_id=c.library_id;

update sbct_acquisti.import_copie as ic set id_copia=c.id_copia
     from sbct_acquisti.copie c where ic.id_copia is null
              and ic.id_titolo=c.id_titolo and ic.budget_id=c.budget_id and ic.library_id=c.library_id and ic.id_ordine=c.id_ordine;

update sbct_acquisti.copie as cp set supplier_id = ic.supplier_id
     from sbct_acquisti.import_copie ic where cp.id_copia = ic.id_copia and cp.supplier_id is null
            and ic.supplier_id notnull;
update sbct_acquisti.copie as cp set id_ordine = ic.id_ordine
     from sbct_acquisti.import_copie ic where cp.id_copia = ic.id_copia and cp.id_ordine is null
            and ic.id_ordine notnull;

update sbct_acquisti.copie set order_status = 'O' where id_ordine is not null and order_status is null;

update sbct_acquisti.copie as cp set order_status = 'S'
     from sbct_acquisti.import_copie ic where cp.id_copia = ic.id_copia and cp.order_status is null;

-- Potrei cancellare i titoli con data di pubblicazione che supera i 60 giorni da oggi, ma in certi casi si verifica errore
-- delete from sbct_acquisti.import_titoli where datapubblicazione > now() + interval '60 days';
-- delete from sbct_acquisti.titoli where datapubblicazione > now() + interval '60 days';

ALTER TABLE sbct_acquisti.titoli ENABLE TRIGGER sbct_acquisti_list_update;
COMMIT;
    }

    sql_file = "/home/seb/load_from_excel#{self.id}.sql"
    fd=File.open(sql_file, "w")
    fd.write(sql)
    fd.close
    self.connection.execute(sql)

    # NON ESEGUIRE LE RIGHE SEGUENTI:
    #config   = Rails.configuration.database_configuration
    #dbname=config[Rails.env]["database"]
    #username=config[Rails.env]["username"]
    #cmd="/usr/bin/psql --no-psqlrc -d #{dbname} #{username}  -f #{sql_file}"
    #Kernel.system(cmd)
    #self.budgets_assign
    #SbctItem.assegna_prezzo
    #SbctBudget.allinea_prezzi_copie
  end

  def cancella_titoli_con_data_di_pubblicazione_futura(giorni_nel_futuro=90)
    raise "giorni_nel_futuro deve essere positivo, non #{giorni_nel_futuro}" if giorni_nel_futuro.to_i < 1
    sql=%Q{
BEGIN;
DELETE FROM sbct_acquisti.import_titoli where id_lista=#{self.id} AND datapubblicazione > now() + interval '#{giorni_nel_futuro} days';
ALTER TABLE sbct_acquisti.titoli DISABLE TRIGGER sbct_acquisti_list_update;
with t1 as
(select t.*,cp.id_copia from sbct_acquisti.titoli t join sbct_acquisti.l_titoli_liste tl using(id_titolo)
  left join sbct_acquisti.copie cp on(cp.id_titolo=t.id_titolo)
  where tl.id_lista=#{self.id}
  and cp.id_copia is null
  and t.created_by is null
  and t.datapubblicazione > now() + interval '#{giorni_nel_futuro} days'
  and t.id_titolo not in (select id_titolo from sbct_acquisti.l_titoli_liste where id_lista!=#{self.id})
)
delete from sbct_acquisti.titoli where id_titolo in (select id_titolo from t1);
ALTER TABLE sbct_acquisti.titoli ENABLE TRIGGER sbct_acquisti_list_update;
COMMIT;
}
    # puts sql
    self.connection.execute(sql)
  end

  def importa_da_liste(lists)
    sql = sql_for_importa_da_liste(lists)
    return if sql.nil?
    self.connection.execute(sql)
  end

  def sql_for_importa_da_liste(lists)
    ids = lists.collect{|r| r.id}
    ids.delete(self.id)
    return nil if ids.size==0
    %Q{INSERT INTO sbct_acquisti.l_titoli_liste (id_titolo, id_lista)
          (select id_titolo,#{self.id} from sbct_acquisti.l_titoli_liste
        WHERE id_lista IN (#{ids.join(',')})) on conflict(id_titolo,id_lista) DO NOTHING;}
  end

  def totale_ordine(budget_id=nil)
    join_budget=budget_id.blank? ? '' : "join sbct_acquisti.budgets b on(b.budget_id=cp.budget_id and b.budget_id=#{budget_id})"
    sql=%Q{SELECT sum(t.prezzo::numeric * numcopie) as totale
             FROM sbct_acquisti.titoli t join sbct_acquisti.copie cp using(id_titolo)
             #{join_budget}
             join sbct_acquisti.l_titoli_liste l using(id_titolo) where l.id_lista=#{self.id};}
    puts sql
    r=self.connection.execute(sql).first['totale']
    r.nil? ? 0 : r
  end

  def sql_for_prepara_ordine(with_sql)
    sql=%Q{with t as(#{with_sql})
SELECT t.titolo,cp.numcopie,cp.id_copia,cp.id_titolo,cp.prezzo as prezzo_scontato, cp.budget_id, cp.order_status,cp.supplier_id,cp.library_id, cp.supplier_id as fornitore,lc.label as siglabiblioteca FROM sbct_acquisti.liste l
      JOIN sbct_acquisti.l_titoli_liste tl using(id_lista)
      JOIN t on(t.id_titolo=tl.id_titolo)
      JOIN sbct_acquisti.copie cp on(cp.id_titolo=tl.id_titolo)
      JOIN sbct_acquisti.budgets b on(b.budget_id=cp.budget_id)
      JOIN clavis.budget cb on(cb.budget_title=l.budget_label)
      JOIN sbct_acquisti.library_codes lc on (lc.clavis_library_id=cp.library_id)
WHERE l.id_lista in(select id_lista from sbct_acquisti.liste where parent_id=#{self.id} or id_lista=#{self.id})
   and b.clavis_budget_id = cb.budget_id
     and cp.supplier_id is  not null
-- STATO ORDINE: Selezionato (S)
    and cp.order_status = 'S'
      AND cp.budget_id = b.budget_id
      AND cb.library_id IN(cp.library_id,1)
     order by t.titolo
    }
    fd=File.open("/home/seb/sbct_sql_for_prepara_ordine.sql", "w")
    fd.write(sql)
    fd.close
    sql
  end

  def assign_user_session(user,current_session)
    puts "In assign_user_session: #{self.id}"
    if self.owner_id==user.id and !self.locked
      return self.id
    end

    if user.role?('AcquisitionLibrarian')
      puts "Sei un AcquisitionLibrarian: #{user.id}"
      user.sbct_lists.each do |l|
        puts "esamino la lista #{l.inspect}"
        if self.owner_id == user.id or (!self.parent_id.nil? and self.parent.owner_id==user.id)
          puts "ok è accessibile: #{self.id}"
          return self.id
        end
      end
      puts "Sei un AcquisitionLibrarian e non hai accesso in scrittura a questa lista #{self.id}"
      return current_session
    end
    if !self.owner_id.nil?
      return current_session if user.id!=self.owner_id
    end
    return current_session if self.locked or self.descendants_index(user).size>0

    self.id
  end
  
  def SbctList.toc(params={})
    cond=[]
    if !params[:old].blank?
      if !params[:id_tipo_titolo].blank?
        cond << "l.id_tipo_titolo = #{self.connection.quote(params[:id_tipo_titolo])}"
      else
        cond << "l.id_tipo_titolo is not null"
      end
    else
      cond << "l.id_tipo_titolo is null"
      cond << "not l.locked" if params[:locked]=='false'
      cond << "l.locked" if params[:locked]=='true'
      cond << "l.parent_id is null"
    end

    cond = cond == [] ? '' : "WHERE #{cond.join(' AND ')}"
    
    sql = %Q{select 
              case when l.data_libri is null then null else l.data_libri end as data_libri,l.hidden,
 l.parent_id,pl.label as parent_list_label,l.label,l.budget_label,l.owner_id,l.id_lista,l.id_tipo_titolo,tp.tipo_titolo,l.locked,count(tl) as cnt
 from sbct_acquisti.liste l
  left join sbct_acquisti.l_titoli_liste tl using(id_lista)
  left join sbct_acquisti.titoli t using(id_titolo)
  left join sbct_acquisti.tipi_titolo tp on(tp.id_tipo_titolo=l.id_tipo_titolo)
  left join sbct_acquisti.liste pl on (pl.id_lista=l.parent_id)
  #{cond}
 group by pl.label,l.data_libri,l.id_lista,l.id_tipo_titolo,tp.tipo_titolo order by l.label,l.data_libri desc, tp.tipo_titolo}



    fd = File.open("/home/seb/sql_for_lists.sql", "w")
    fd.write(sql)
    fd.close
    
    if params=={}
      self.connection.execute(sql).to_a
    else
      self.paginate_by_sql(sql, per_page:100, page:params[:page])
    end
  end

  def SbctList.label_select(parent_id)
    sql=%Q{select id_lista as key,case when label isnull then data_libri::varchar else label end as label from sbct_acquisti.liste where id_lista=#{parent_id.to_i}}
    i = self.connection.execute(sql).to_a.first
    first_line = [i['label'],i['key']]
    # collect {|i| 
    # return first_line
    # sql=%Q{select id_lista as key,label from sbct_acquisti.liste where label is not null order by label}
    sql=%Q{select id_lista as key,case when label isnull then data_libri::varchar else label end as label
             from sbct_acquisti.liste where parent_id=#{parent_id.to_i} order by label}
    res = self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
    res.insert(0,first_line)
  end

  def SbctList.totale_ordine(list_ids)
    t=0.0
    list_ids.each do |id|
      puts "id: #{id}"
      x = SbctList.find(id).totale_ordine.to_f
      puts x
      t += x
    end
    t
  end

  def SbctList.clavis_label_select
    self.connection.execute(SbctList.sql_for_clavis_label_select).collect {|i| [i['budget_title'],i['budget_title']]}
  end

  def SbctList.sql_for_clavis_label_select(budget_label=nil)
    where = budget_label.nil? ? '' : "WHERE cb.budget_title=#{self.connection.quote(budget_label)}"
    sql = %Q{
      SELECT cb.budget_title,
          array_to_string(array_agg(b.budget_id order by cb.library_id), ',') as budget_ids,
          array_to_string(array_agg(cb.budget_id order by cb.library_id), ',') as clavis_budget_ids,
          array_to_string(array_agg(cb.library_id order by cb.library_id), ',') as library_ids
        FROM sbct_acquisti.budgets b join clavis.budget cb ON (cb.budget_id = b.clavis_budget_id)
        #{where} group by cb.budget_title;
    }
  end

  def SbctList.list_select(current_list=nil)
    if !current_list.nil?
      cond = current_list.id.nil? ? '' : "and id_lista!=#{current_list.id}"
    end
    sql = %Q{select label,id_lista from sbct_acquisti.liste where label notnull #{cond} order by lower(label);}
    self.connection.execute(sql).collect {|i| [i['label'],i['id_lista']]}    
  end

end
