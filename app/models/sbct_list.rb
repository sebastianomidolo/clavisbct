# coding: utf-8
class SbctList < ActiveRecord::Base

  self.table_name='sbct_acquisti.liste'

  attr_accessible :id_tipo_titolo, :label, :budget_label
  before_save :check_record

  has_and_belongs_to_many(:sbct_titles, join_table:'sbct_acquisti.l_titoli_liste',
                          :foreign_key=>'id_lista',
                          :association_foreign_key=>'id_titolo')


  def to_label
    if self.label.blank?
      "#{self.data_libri} #{self.label} tipo #{self.id_tipo_titolo}"
    else
      "#{self.label}"
    end
  end

  def check_record
    assegna_fornitore if !self.id.nil?
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
    #fd=File.open("/home/seb/ricalcola_prezzi.sql", "w")
    #fd.write(sql)
    #fd.close
    self.connection.execute(sql)    
  end

  def assegna_fornitore
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
  def budgets_assign
    sql = sql_for_budgets_assign
    return nil if sql.blank?
    puts "Assegno budget #{self.budget_label}"
    puts sql
    self.connection.execute(sql)
  end

  def sql_for_budgets_assign
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
        from lecopie where cp.id_copia = lecopie.id_copia and cp.budget_id is null and cp.supplier_id is null;}
  end

  def load_data_from_excel(sourcefile, current_user)
    require 'open3'
    cmd = %Q{Rscript /home/ror/clavisbct/extras/R/carica_excel.r "#{sourcefile}"}
    @stdout,@stderr,@status=Open3.capture3(cmd)
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
    csv.each do |r|
      r << date_created
      r << current_user.id
      r << self.id
      r << original_filename
      values = r.collect {|d| d=='NULL' ? d : self.connection.quote(d)}
      sql << "INSERT INTO sbct_acquisti.import_titoli (#{columns.join(',')}) VALUES(#{values.join(',')});"
    end
    self.connection.execute(sql.join(";\n"))
          
    sql=%Q{
update sbct_acquisti.import_titoli as i set id_titolo=t.id_titolo from sbct_acquisti.titoli t where i.id_titolo is null and i.ean = t.ean;

update sbct_acquisti.titoli t set reparto=v.reparto, sottoreparto=v.sottoreparto,target_lettura=v.target_lettura,
        anno = v.anno, prezzo = v.prezzo,
        datapubblicazione = v.datapubblicazione from sbct_acquisti.import_titoli v where v.id_titolo=t.id_titolo;

update sbct_acquisti.titoli t set  anno = v.anno from sbct_acquisti.import_titoli v where v.id_titolo=t.id_titolo;

insert into sbct_acquisti.titoli
             (ean,isbn,editore,autore,titolo,collana,prezzo,datapubblicazione,reparto,sottoreparto)
      (SELECT ean, ean,editore,autore,titolo,collana,prezzo,datapubblicazione,reparto,sottoreparto
         FROM sbct_acquisti.import_titoli WHERE id_titolo is null and ean is not null);


      UPDATE sbct_acquisti.import_titoli as i set id_titolo=t.id_titolo from sbct_acquisti.titoli t where i.id_titolo is null and i.ean = t.ean;
      insert into sbct_acquisti.l_titoli_liste(id_titolo,id_lista)
         (select id_titolo,id_lista from sbct_acquisti.import_titoli where id_titolo notnull) on conflict(id_titolo,id_lista) DO NOTHING;
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

with t1 as
  (select id_copia,id_ordine,substr(id_ordine, 3, 4) as year, substr(id_ordine, 8, 2) as month  from sbct_acquisti.copie where id_ordine is not null
        and order_date is null)
UPDATE sbct_acquisti.copie c SET order_date=concat(t1.year, '-', t1.month, '-', '01')::date from t1 where t1.id_copia=c.id_copia;
    }

    sql_file = "/home/seb/load_from_excel#{self.id}.sql"
    fd=File.open(sql_file, "w")
    fd.write(sql)
    fd.close
    self.connection.execute(sql)
    #config   = Rails.configuration.database_configuration
    #dbname=config[Rails.env]["database"]
    #username=config[Rails.env]["username"]
    #cmd="/usr/bin/psql --no-psqlrc -d #{dbname} #{username}  -f #{sql_file}"
    #Kernel.system(cmd)
    self.budgets_assign
    SbctItem.assegna_prezzo
    SbctBudget.allinea_prezzi_copie
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

  def sql_for_prepara_ordine
    %Q{
SELECT t.titolo,cp.numcopie,cp.id_copia,cp.id_titolo,cp.prezzo, cp.budget_id, cp.order_status,cp.supplier_id,cp.library_id, cp.supplier_id as fornitore,lc.label as siglabiblioteca FROM sbct_acquisti.liste l
      JOIN sbct_acquisti.l_titoli_liste tl using(id_lista)
      JOIN sbct_acquisti.titoli t on(t.id_titolo=tl.id_titolo)
      JOIN sbct_acquisti.copie cp on(cp.id_titolo=tl.id_titolo)
      JOIN sbct_acquisti.budgets b on(b.budget_id=cp.budget_id)
      JOIN clavis.budget cb on(cb.budget_title=l.budget_label)
      JOIN sbct_acquisti.library_codes lc on (lc.clavis_library_id=cp.library_id)
WHERE l.id_lista = #{self.id} 
-- (VALUTARE SE USARE QUESTA CONDIZIONE):
   and b.clavis_budget_id = cb.budget_id
     and cp.supplier_id is  not null
-- STATO ORDINE: Selezionato (S)
    and cp.order_status = 'S'
      AND cp.budget_id = b.budget_id
      AND cb.library_id IN(cp.library_id,1)
     order by t.id_titolo

    }
  end

  
  def SbctList.toc(params={})
    cond=[]
    if !params[:id_tipo_titolo].blank?
      cond << "l.id_tipo_titolo = #{self.connection.quote(params[:id_tipo_titolo])}"
    else
      cond << "l.id_tipo_titolo is null"
    end
    cond = cond == [] ? '' : "WHERE #{cond.join('AND')}"
    
    sql = %Q{select 
              case when l.data_libri is null then null else l.data_libri end as data_libri,
              l.label,l.budget_label,l.id_lista,l.id_tipo_titolo,tp.tipo_titolo,count(tl) as cnt
             from sbct_acquisti.liste l
             left join sbct_acquisti.l_titoli_liste tl using(id_lista)
             left join sbct_acquisti.titoli t using(id_titolo)
             left join sbct_acquisti.tipi_titolo tp on(tp.id_tipo_titolo=l.id_tipo_titolo) #{cond}
             group by l.data_libri,l.id_lista,l.id_tipo_titolo,tp.tipo_titolo order by label,data_libri desc, tp.tipo_titolo}
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
  
end
