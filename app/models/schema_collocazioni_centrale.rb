# coding: utf-8
class SchemaCollocazioniCentrale < ActiveRecord::Base
  self.table_name='schema_collocazioni_centrale'
  attr_accessible :piano, :scaffale, :palchetto, :filtro_colloc, :bib_section_id, :notes, :locked
  belongs_to :bib_section
  before_save :check_record
  after_save :update_centrale_locations

  # before_save
  def check_record
    self.filtro_colloc = nil if self.filtro_colloc.blank?
    self.scaffale = nil if self.scaffale.blank?
    self.palchetto = nil if self.palchetto.blank?
    self.notes = nil if self.notes.blank?
  end

  def update_centrale_locations
    return if sql_for_update_centrale_locations.nil?
    return self.connection.execute(sql_for_update_centrale_locations).cmd_tuples
  end

  def conditions_for_update_centrale_locations(ignore_locked=false)
    conditions = []
    if !scaffale.nil?
      from,to=scaffale.split('-')
      if from.to_i == 0
        conditions << (to.nil? ? "primo_elemento = '#{from}'" : "primo_elemento between '#{from}' and '#{to}'")
      else
        conditions << (to.nil? ? "scaffale = #{from}" : "scaffale between #{from} and #{to}")
      end
    end
    if !palchetto.nil?
      r=[]
      palchetto.split(',').each do |p|
        from,to=p.split('-')
        r << (to.nil? ? from : (from..to).to_a)
      end
      r = r.flatten.collect {|p| "'#{p}'"}
      if (palchetto =~ /^~/)
        conditions << "secondo_elemento #{palchetto}"
      else
        conditions << (r.size==1 ? "secondo_elemento = #{r.join}" : "secondo_elemento IN(#{r.join(',')})")
      end
    end
    if !filtro_colloc.nil?
      conditions << "(#{filtro_colloc})"
    end
    conditions << 'piano is null' if !ignore_locked && !self.locked?
    conditions.join(' and ')
  end

  def sql_for_update_centrale_locations
    return nil if self.conditions_for_update_centrale_locations.blank?
    "UPDATE clavis.centrale_locations SET piano='#{self.bib_section.name}' WHERE #{self.conditions_for_update_centrale_locations};"
  end

  def sql_for_select_from_centrale_locations
    sql = self.conditions_for_update_centrale_locations(true)
    return nil if sql.blank?
    "SELECT * FROM clavis.centrale_locations WHERE #{sql} ORDER BY espandi_collocazione(collocazione) LIMIT 100;"
  end

  def self.list(p={})
    order = p[:order].nil? ? '' : "order by #{p[:order]}"
    cond = p[:conditions].blank? ? '' : "WHERE #{p[:conditions].join(' AND ')}"
    sql=%Q{select sc.*,bs.name as piano from #{self.table_name} sc join bib_sections bs on(bs.id=sc.bib_section_id) #{cond} #{order}}
    self.find_by_sql(sql)
  end

  def self.trova_piano(collocazione)
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

  def self.update_all_centrale_locations
    vsql=[]
    # nulls last è pleonastico perché è già il comportamento di default, ma lo specifico ugualmente
    # per chiarezza sulle intenzioni
    sql = "select * from schema_collocazioni_centrale order by locked desc,scaffale nulls last,palchetto nulls last"
    res=self.find_by_sql(sql)
    res.each do |r|
      vsql << r.sql_for_update_centrale_locations
      r.connection.execute r.sql_for_update_centrale_locations
    end

    # PER dal 2012 in poi, al settimo piano
    # I libri nei contenitori sono contrassegnati com "Cassa deposito esterno"
    sql=%Q{update clavis.centrale_locations as cl set piano='8° piano' from clavis.item ci
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
    return vsql.join("\n")
  end
end
