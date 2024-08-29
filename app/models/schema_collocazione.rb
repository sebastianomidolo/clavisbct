 # coding: utf-8
class Location < ActiveRecord::Base
  attr_accessible :primo, :secondo, :terzo, :sql_filter, :bib_section_id, :notes, :locked, :library_id
  belongs_to :bib_section
  belongs_to :clavis_library, foreign_key:'library_id'
  before_save :check_record

  
  after_save :update_locations

  # before_save
  def check_record
    self.filtro_colloc = nil if self.filtro_colloc.blank?
    self.scaffale = nil if self.scaffale.blank?
    self.palchetto = nil if self.palchetto.blank?
    self.notes = nil if self.notes.blank?
  end

  def update_locations
    return if sql_for_update_locations.nil?
    return self.connection.execute(sql_for_update_locations).cmd_tuples
  end

  def items_count
    cond = []
    cond << self.conditions_for_update_locations(true,'cl')
    cond << "cl.piano=#{self.connection.quote(self.bib_section.name)}"
    cond = cond.join(" AND ")
    sql = %Q{with t1 as (select * from clavis.centrale_locations cl WHERE #{cond})
       select count(*) from t1;}
    # puts sql
    begin
      self.connection.execute(sql).first
    rescue
      -1
    end
  end
  def items_details(verbose=false,exec=true)
    if verbose==false
      sql = %Q{with t1 as (select * from clavis.centrale_locations cl WHERE cl.piano='#{self.bib_section.name}' and #{self.conditions_for_update_centrale_locations(true,'cl')})  
    select ci.item_media as tipologia,ci.item_media,
       case when ci.item_status is null then '(topografico)' else ci.item_status end as stato,
       case when ci.item_status is null then 'NULL' else ci.item_status end as item_status,count(*) as volumi
     from t1 join clavis.item ci using(item_id)
     group by 1,2,3,4 order by tipologia,count(*) desc, stato;}
    else
      sql = %Q{with t1 as (select * from clavis.centrale_locations cl WHERE cl.piano='#{self.bib_section.name}' and #{self.conditions_for_update_centrale_locations(true,'cl')})  
    select m.value_label as tipologia,
       case when s.value_label is null then '(topografico)' else s.value_label end as stato,
        m.value_key as item_media,
       case when s.value_key is null then 'NULL' else s.value_key end as item_status,
       count(*) as volumi
     from t1 join clavis.item ci using(item_id)
        left join clavis.lookup_value m on(m.value_key=ci.item_media  AND m.value_language = 'it_IT' AND m.value_class ~ 'ITEMMEDIA')
        left join clavis.lookup_value s on(s.value_key=ci.item_status AND s.value_language = 'it_IT' AND s.value_class ~ 'ITEMSTATUS')
     group by 1,2,3,4 order by tipologia,count(*) desc, stato;}
    end
    return sql if exec==false
    self.connection.execute(sql).to_a
  end

  def items_series(verbose=false,exec=true)
    if verbose==false
      sql = %Q{with t1 as (select * from clavis.centrale_locations cl WHERE cl.piano='#{self.bib_section.name}' and #{self.conditions_for_update_centrale_locations(true,'cl')})
         select ci.inventory_serie_id as serie,ci.inventory_serie_id as description,count(*) as volumi from t1 join clavis.item ci using(item_id)
          group by 1,2 order by 1,2;}
    else
      sql = %Q{with t1 as (select * from clavis.centrale_locations cl WHERE cl.piano='#{self.bib_section.name}' and #{self.conditions_for_update_centrale_locations(true,'cl')})
       select s.inventory_serie_id as serie,s.description,count(*) as volumi from t1 join clavis.item ci using(item_id)
          join clavis.inventory_serie s on(s.inventory_serie_id=ci.inventory_serie_id and s.library_id=ci.home_library_id)
           group by 1,2 order by 1,2;}
    end
    return sql if exec==false
    self.connection.execute(sql).to_a
  end

  def items_edition_dates(verbose=false,exec=true)
    sql = %Q{with t1 as (select * from clavis.centrale_locations cl WHERE cl.piano='#{self.bib_section.name}' and #{self.conditions_for_update_centrale_locations(true,'cl')})
    select cm.edition_date, count(*) as volumi
       from t1 join clavis.item ci using(item_id)
       join clavis.manifestation cm using(manifestation_id)
   group by 1 order by cm.edition_date;}
    return sql if exec==false
    self.connection.execute(sql).to_a
  end

  def conditions_for_update_locations(ignore_locked=false,table_alias='cl')
    tbl = table_alias.blank? ? '' : "#{table_alias}."
    conditions = []
    if !self.primo.nil?
      from,to=self.primo.split('-')
      conditions << (to.nil? ? "#{tbl}primo = '#{from}'" : "#{tbl}primo between '#{from}' and '#{to}'")
    end

    if !self.secondo.nil?
      r=[]
      self.secondo.split(',').each do |p|
        from,to=p.split('-')
        r << (to.nil? ? from : (from..to).to_a)
      end
      r = r.flatten.collect {|p| "'#{p}'"}
      if (self.secondo =~ /^~/)
        conditions << "#{tbl}secondo #{self.secondo}"
      else
        conditions << (r.size==1 ? "#{tbl}secondo = #{r.join}" : "#{tbl}secondo IN(#{r.join(',')})")
      end
    end
    # return conditions.join(' and ')

    if !sql_filter.nil?
      conditions << "(#{sql_filter})"
    end
    conditions << "#{tbl}schema_collocazione_id is null" if !ignore_locked && !self.locked?
    conditions.join(' and ')
  end

  def sql_for_update_locations
    cnd = self.conditions_for_update_locations
    return nil if cnd.blank?
    %Q{UPDATE clavis.collocazioni cl set schema_collocazione_id=#{self.id} WHERE #{cnd}}
  end

  def Location.list(p={})
    order = p[:order].nil? ? '' : "order by #{p[:order]}"
    cond = p[:conditions].blank? ? '' : "WHERE #{p[:conditions].join(' AND ')}"
    sql=%Q{select sc.*,bs.name as piano from view_schema_collocazioni sc join bib_sections bs on(bs.id=sc.bib_section_id) #{cond} #{order}}
    self.find_by_sql(sql)
  end

  def Location.trova_piano(collocazione,library_id)
    puts "trovo il piano per la collocazione #{collocazione}"
    return nil if collocazione.strip.blank?
    scaffale,palchetto,catena = collocazione.split('.')
    puts "scaffale: #{scaffale}"
    puts "palchetto: #{palchetto}"
    puts "catena: #{catena}"
    sql=%Q{select bs.name as piano,scaffale,palchetto,filtro_colloc,locked from schema_collocazioni_centrale sc
             join bib_sections bs on (bs.id=sc.bib_section_id)
              order by locked desc,scaffale nulls last,palchetto nulls last}

    tuples=self.connection.execute(sql).to_a
    candidates=[]
    tuples.each do |r|
      (candidates << r and next) if r['scaffale'].blank? and !palchetto.blank?
      if SchemaCollocazioniCentrale.check_if_exists_in_range(scaffale, r['scaffale'])
        candidates << r
        next
      end
      next if r['palchetto'].blank?
      r['palchetto'].split(",").each do p
        if SchemaCollocazioniCentrale.check_if_exists_in_range(palchetto, p)
          candidates << r
        end
      end
    end

    puts "Candidati per scaffale '#{scaffale}' - palchetto '#{palchetto}' - catena '#{catena}'"
    candidates.each do |r|
      puts r.inspect
    end
    puts "#{candidates.size} candidati\n---\n"

    retval=[]
    candidates.each do |r|
      puts r.inspect
      if r['scaffale'].blank? and !r['palchetto'].blank? and !palchetto.blank?
        puts "scaffale nil, procedo esaminando palchetto #{r['palchetto']}"
        if SchemaCollocazioniCentrale.check_if_exists_in_range(palchetto, r['palchetto'])
          puts "trovato!"
          retval << r['piano']
          break
        end
      else
        if SchemaCollocazioniCentrale.check_if_exists_in_range(scaffale, r['scaffale'])
          puts "trovato scaffale #{scaffale}"
          if palchetto.blank?
            puts "non mi interessa il palchetto, ma solo lo scaffale #{scaffale}"
            retval << r['piano']
          else
            puts "Cerco il palchetto #{palchetto} nello scaffale #{scaffale} (possibili: #{r['palchetto']})"
            if !r['palchetto'].blank? and SchemaCollocazioniCentrale.check_if_exists_in_range(palchetto, r['palchetto'])
              puts "trovato palchetto #{palchetto}"
              retval << r['piano']
              break
            else
              if r['palchetto'].blank?
                puts "palchetto blank in #{r.inspect}"
                retval << r['piano']
                break
              else
              end
            end
          end
        end
      end
    end
    retval.uniq.join(', ')
  end

  # Sostituirà trova_piano
  def SchemaCollocazioniCentrale.find_bib_section(collocazione,library_id)
    puts "trovo il piano per la collocazione #{collocazione} della biblioteca #{library_id}"
    return nil if collocazione.strip.blank?
    scaffale,palchetto,catena = collocazione.split('.')
    puts "scaffale: #{scaffale}"
    puts "palchetto: #{palchetto}"
    puts "catena: #{catena}"

    sql=%Q{select bs.id,bs.name as piano,sc.library_id,scaffale,palchetto,filtro_colloc,locked from schema_collocazioni_centrale sc
             join bib_sections bs on (bs.id=sc.bib_section_id) WHERE sc.library_id=#{library_id}
              order by locked desc,scaffale nulls last,palchetto nulls last}
    tuples=self.connection.execute(sql).to_a
    candidates=[]
    tuples.each do |r|
      (candidates << r and next) if r['scaffale'].blank? and !palchetto.blank?
      if SchemaCollocazioniCentrale.check_if_exists_in_range(scaffale, r['scaffale'])
        candidates << r
        next
      end
      next if r['palchetto'].blank?
      r['palchetto'].split(",").each do p
        if SchemaCollocazioniCentrale.check_if_exists_in_range(palchetto, p)
          candidates << r
        end
      end
    end

    puts "Candidati per scaffale '#{scaffale}' - palchetto '#{palchetto}' - catena '#{catena}'"
    candidates.each do |r|
      puts r.inspect
    end
    puts "#{candidates.size} candidati\n---\n"

    retval=[]
    candidates.each do |r|
      puts r.inspect
      if r['scaffale'].blank? and !r['palchetto'].blank? and !palchetto.blank?
        puts "scaffale nil, procedo esaminando palchetto #{r['palchetto']}"
        if SchemaCollocazioniCentrale.check_if_exists_in_range(palchetto, r['palchetto'])
          puts "trovato!"
          retval << r['piano']
          break
        end
      else
        if SchemaCollocazioniCentrale.check_if_exists_in_range(scaffale, r['scaffale'])
          puts "trovato scaffale #{scaffale}"
          if palchetto.blank?
            puts "non mi interessa il palchetto, ma solo lo scaffale #{scaffale}"
            retval << r['piano']
          else
            puts "Cerco il palchetto #{palchetto} nello scaffale #{scaffale} (possibili: #{r['palchetto']})"
            if !r['palchetto'].blank? and SchemaCollocazioniCentrale.check_if_exists_in_range(palchetto, r['palchetto'])
              puts "trovato palchetto #{palchetto}"
              retval << r['piano']
              break
            else
              if r['palchetto'].blank?
                puts "palchetto blank in #{r.inspect}"
                retval << r['piano']
                break
              else
              end
            end
          end
        end
      end
    end
    retval.uniq.join(', ')
  end
  
  def self.check_if_exists_in_range(element,range)
    range.to_s.split(',').each do |r|
      return true if self.check_if_exists_in_range_do(element,r)
    end
    false
  end
  
  # range potrebbe essere "A-B" oppure solo "A" (non sarebbe un range, ma lo considero tale ugualmente)
  # Inoltre sia l'elemento sia il range possono essere numerici o alfabetici e vanno trattati di conseguenza
  def self.check_if_exists_in_range_do(element,range)
    # puts "controllo se #{element} si trova in #{range}"
    # Tipo di confronto che intendo effettuare, può essere "number" o "alpha"
    # Assumo number
    cfr = 'number'
    range = range.to_s
    from,to=range.split('-')
    if range =~ /^~/
      range_is_regexp=true
    else
      range_is_regexp=false
    end
    Integer(element) rescue cfr='alpha'
    Integer(from) rescue cfr='alpha'
    Integer(to) rescue cfr='alpha' if !to.nil?
    if cfr=='alpha'
      element=element.to_s.downcase
      from=from.to_s.downcase
      to=to.to_s.downcase if !to.nil?
    else
      element=element.to_i
      from=from.to_i
      to=to.to_i if !to.nil?
    end
    if range_is_regexp
      range.gsub!(/^~ */, '')
      range.gsub!(/^\'|\'?$/, '')
      r=Regexp.new(range, 'i')
      puts "considero come regexp: #{r.inspect} da confrontare con #{element} (#{!(element =~ r).nil?})"
      return !(element =~ r).nil?
    else
      if to.nil?
        puts "elemento #{element} === #{from} (#{(element.blank? or from.blank?) ? false : element===from})"
        return (element.blank? or from.blank?) ? false : element===from
      else
        puts "elemento #{element} between #{from} and #{to} (#{element.between?(from,to)})"
        return element.between?(from,to)
      end
    end
  end

  def SchemaCollocazioniCentrale.update_all_centrale_locations
    vsql=[]
    # nulls last è pleonastico perché è già il comportamento di default, ma lo specifico ugualmente
    # per chiarezza sulle intenzioni
    sql = "select * from schema_collocazioni_centrale order by locked desc,scaffale nulls last,palchetto nulls last"
    res=self.find_by_sql(sql)
    res.each do |r|
      tsql = r.sql_for_update_centrale_locations
      next if tsql.blank?
      begin
        r.connection.execute(tsql)
      rescue
        puts "errore per schema collocazione #{r.id} - #{$!}: sql: #{tsql}"
        next
      end
      # vsql << tsql
    end

    # PER dal 2012 in poi, al settimo piano
    # I libri nei contenitori sono contrassegnati com "Cassa deposito esterno"
    sql=%Q{update clavis.centrale_locations as cl set piano='7° piano' from clavis.item ci
             where ci.item_id=cl.item_id and cl.primo_elemento = 'PER' and ci.issue_year ~  '^\\d+$'
              and ci.issue_year::integer > 2011;
           update clavis.centrale_locations cl set piano='Cassa deposito esterno' from container_items ci
             join containers c on(c.id=ci.container_id) join clavis.library l on(l.library_id=c.library_id)
              where ci.item_id=cl.item_id;}
    self.connection.execute(sql)
    vsql << sql
    fd=File.open("/tmp/updates.sql", "w")
    fd.write(vsql.join("\n") + "\n")
    fd.close
    return true
  end

  # Derivata da update_all_centrale_locations - 20 agosto 2023
  def SchemaCollocazioniCentrale.update_all_locations(library_id=nil)
    vsql=[]
    where = library_id.nil? ? '' : "WHERE library_id=#{library_id.to_i}"
    # nulls last è pleonastico perché è già il comportamento di default, ma lo specifico ugualmente
    # per chiarezza sulle intenzioni
    sql = %Q{select id,library_id,primo,secondo,terzo,sql_filter
       from public.view_schema_collocazioni #{where} order by locked desc,primo nulls last,secondo nulls last;}
    puts sql
    res=self.find_by_sql(sql)
    res.each do |r|
      tsql = r.sql_for_update_locations
      next if tsql.blank?
      # puts tsql
      begin
        r.connection.execute(tsql)
      rescue
        puts "errore per schema collocazione #{r.id} - #{$!}: sql: #{tsql}"
        next
      end
      # vsql << tsql
    end
    true
  end

end
