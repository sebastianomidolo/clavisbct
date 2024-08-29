 # coding: utf-8
class Location < ActiveRecord::Base
  attr_accessible :primo, :secondo, :terzo, :sql_filter, :bib_section_id, :notes, :locked, :library_id
  attr_accessor :library_id, :shelf_id

  belongs_to :bib_section
  before_save :check_record

  belongs_to :clavis_library, foreign_key:'library_id'
  
  after_save :update_items

  def to_label
    self.notes.blank? ? self.bib_section.to_label : "#{self.bib_section.to_label}. #{self.notes}"
  end

  # before_save
  def check_record
    #['primo', 'secondo', 'terzo', 'notes', 'sql_filter', ].each do |f|
    #  self.assign_attributes(f=>nil) if self.send(f).blank?
    #end
    self.attribute_names.each do |f|
      self.assign_attributes(f=>nil) if self.send(f).blank?
    end
    self
  end

  def collocazione_intera(html=true)
    html ? %Q{<span class="label label-success">#{self.primo}</span>.<span class="label label-info">#{self.secondo}</span>.<span class="label label-warning">#{self.terzo}</span>} : [self.primo,self.secondo,self.terzo].join('.')
  end

  def update_items(schema='clavis')
    sql=self.sql_for_update_items
    return if sql.nil?
    # puts sql
    self.connection.execute(sql)
  end

  def items_count
    sql = "select count(*) from clavis.collocazioni where location_id=#{self.id};"
    # puts sql
    self.connection.execute(sql).first['count'].to_i
  end

  def items_details(verbose=false,exec=true)
    if verbose==false
      sql = %Q{with t1 as (select * from clavis.locations cl WHERE cl.piano='#{self.bib_section.name}' and #{self.conditions_for_update_items(true,'cl')})  
    select ci.item_media as tipologia,ci.item_media,
       case when ci.item_status is null then '(topografico)' else ci.item_status end as stato,
       case when ci.item_status is null then 'NULL' else ci.item_status end as item_status,count(*) as volumi
     from t1 join clavis.item ci using(item_id)
     group by 1,2,3,4 order by tipologia,count(*) desc, stato;}
    else
      sql = %Q{with t1 as (select * from public.locations cl WHERE cl.piano='#{self.bib_section.name}' and #{self.conditions_for_update_items(true,'cl')})  
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

  def set_condition(attr_name,table_alias='cl')
    tbl = table_alias.blank? ? '' : "#{table_alias}."
    data = self.send(attr_name)
    cond = []
    if !data.nil?
      if (data =~ /^~/)
        cond << "#{tbl}#{attr_name} #{data}"
      else
        data.split(',').each do |p|
          # puts "p: #{p}"
          from,to=p.split('-')
          if from.to_i > 0
            cond << (to.nil? ? "#{tbl}#{attr_name}_i = #{from}" : "#{tbl}#{attr_name}_i between #{from} and #{to}")
          else
            if to.nil?
              cond << "#{tbl}#{attr_name} = '#{from}'"
            else
              rn=(from..to).to_a.collect {|i| "'#{i}'"}
              # puts rn.join(',')
              # cond << "#{tbl}#{attr_name} between '#{from}' and '#{to}'"
              cond << "#{tbl}#{attr_name} IN(#{rn.join(',')})"
            end
            # cond << (to.nil? ? "#{tbl}#{attr_name} = '#{from}'" : "#{tbl}#{attr_name} between '#{from}' and '#{to}'")
          end
        end
      end
    end
    cond.join(' OR ')
  end

  def conditions_for_update_items(ignore_locked=false,table_alias='cl')
    tbl = table_alias.blank? ? '' : "#{table_alias}."
    conditions = []

    if !self.shelf_id.blank?
      puts "Prendi da scaffale #{self.shelf_id}"
      conditions << "ci.item_id IN (select object_id from clavis.shelf_item where shelf_id = #{self.shelf_id.to_i} and object_class='item')"
    end
    ['primo','secondo','terzo'].each do |a|
      v = self.set_condition(a, table_alias)
      conditions << "( #{v} )" if !v.blank?
    end
    if !sql_filter.blank?
      conditions << "(#{sql_filter})"
    end
    return '' if conditions.size==0
    conditions << "ci.home_library_id=#{self.bib_section.library_id}"
    conditions << "#{tbl}location_id is null" if !ignore_locked && !self.locked?
    conditions.join(' and ')
  end

  def sql_for_update_items(schema='clavis')
    cnd = self.conditions_for_update_items
    return nil if cnd.blank?
    %Q{
BEGIN;
UPDATE #{schema}.collocazioni set location_id=NULL WHERE location_id=#{self.id};
UPDATE #{schema}.collocazioni cl set location_id=#{self.id} FROM #{schema}.item ci WHERE cl.item_id=ci.item_id and #{cnd};
COMMIT;
       }
  end

  def sql_for_update_super_items(schema='clavis')
    cnd = self.conditions_for_update_items
    return nil if cnd.blank?
    %Q{
BEGIN;
UPDATE #{schema}.collocazioni set location_id=NULL WHERE location_id=#{self.id};
UPDATE #{schema}.collocazioni cl set location_id=#{self.id} FROM #{schema}.super_items ci WHERE cl.item_id=ci.item_id and #{cnd};
COMMIT;
       }
  end

  
  def Location.list(p={})
    # order = p[:order].nil? ? '' : "order by #{p[:order]}"
    # raise "#{p[:order]}"
    order = 'primo,loc_name,notes,secondo'
    case p[:order]
    when '2e'
      order = 'secondo'
    when 'id'
      order = 'id desc'
    when 'p'
      order = 'loc_name,primo,secondo'
    end
    cond = p[:conditions].blank? ? '' : "WHERE #{p[:conditions].join(' AND ')}"
    # sql=%Q{select sc.* from view_locations sc join bib_sections bs on(bs.id=sc.bib_section_id) #{cond} #{order}}
    sql=%Q{select * from view_locations #{cond} order by #{order}}
    # raise sql
    # puts sql
    Location.find_by_sql(sql)
  end

  def Location.find_bib_section(collocazione,library_id)
    #puts "Cerco bib_section per la collocazione #{collocazione} della biblioteca #{library_id}"
    return nil if collocazione.strip.blank?
    primo,secondo,terzo = collocazione.split('.')
    #puts "primo: #{primo}"
    #puts "secondo: #{secondo}"
    #puts "terzo: #{terzo}"
    sql = %Q{select bs.name as loc_name,loc.bib_section_id,primo,secondo,sql_filter,locked from public.locations loc
             join public.bib_sections bs on (bs.id=loc.bib_section_id) WHERE bs.library_id=#{library_id}
              order by locked desc,primo nulls last,secondo nulls last}
    #puts sql
    locations = Location.find_by_sql(sql)
    candidates=[]
    locations.each do |r|
      (candidates << r and next) if r.primo.blank? and !secondo.blank?
      if Location.check_if_exists_in_range(primo, r.primo)
        candidates << r
        next
      end
      next if r.secondo.blank?
      r.secondo.split(",").each do p
        if Location.check_if_exists_in_range(secondo, p)
          candidates << r
        end
      end
    end
    # puts "Candidati per primo elemento '#{primo}' - secondo elemento '#{secondo}' - terzo '#{terzo}'"
    candidates.each do |r|
      # puts r.inspect
    end
    # puts "#{candidates.size} candidati\n"

    retval=nil
    candidates.each do |r|
      # puts r.inspect
      bib_section_id = r.bib_section_id.to_i
      if r.primo.blank? and !r.secondo.blank? and !secondo.blank?
        # puts "primo elemento nil, procedo esaminando secondo elemento #{r.secondo}"
        if Location.check_if_exists_in_range(secondo, r.secondo)
          # puts "trovato qui!"
          retval = bib_section_id
          break
        end
      else
        if Location.check_if_exists_in_range(primo, r.primo)
          # puts "trovato primo qui #{primo}"
          if secondo.blank?
            # puts "non mi interessa il secondo, ma solo il primo elemento: #{primo}"
            retval = bib_section_id
          else
            # puts "Cerco il secondo #{secondo} nello primo #{primo} (possibili: #{r.secondo})"
            if !r.secondo.blank? and Location.check_if_exists_in_range(secondo, r.secondo)
              # puts "trovato secondo #{secondo}"
              retval = bib_section_id
              break
            else
              if r.secondo.blank?
                # puts "secondo blank in #{r.inspect}"
                retval = bib_section_id
                break
              else
              end
            end
          end
        end
      end
    end
    retval
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
      # puts "considero come regexp: #{r.inspect} da confrontare con #{element} (#{!(element =~ r).nil?})"
      return !(element =~ r).nil?
    else
      if to.nil?
        # puts "elemento #{element} === #{from} (#{(element.blank? or from.blank?) ? false : element===from})"
        return (element.blank? or from.blank?) ? false : element===from
      else
        # puts "elemento #{element} between #{from} and #{to} (#{element.between?(from,to)})"
        return element.between?(from,to)
      end
    end
  end

  def Location.update_all_items(library_id=nil, schema='clavis')
    where = library_id.nil? ? '' : "WHERE library_id=#{library_id.to_i}"
    # nulls last è pleonastico perché è già il comportamento di default, ma lo specifico ugualmente
    # per chiarezza sulle intenzioni
    sql = %Q{select * from public.view_locations #{where} order by locked desc,primo nulls last,secondo nulls last;}
    # puts sql
    res=Location.find_by_sql(sql)
    res.each do |r|
      begin
        # puts "update_items per #{r.id} - #{r.collocazione_intera(html=false)}"
        r.update_items(schema)
      rescue
        puts "errore per location #{r.id} - #{$!}"
      end
    end
    true
  end

  def Location.options_for_select(library_id)
    r = Location.find_by_sql("SELECT * FROM public.view_locations where library_id=#{library_id.to_i} ORDER BY loc_name, notes nulls first")
    r.collect do |x|
      t = x.collocazione_intera(html=false)
      t = '' if t == ".."
      t = " - #{t}" if !t.blank?
      name = x.loc_name
      name << ". #{x.notes}" if !x.notes.blank?
      ["#{name[0..50]}#{t}",x.id]
    end
  end

end
