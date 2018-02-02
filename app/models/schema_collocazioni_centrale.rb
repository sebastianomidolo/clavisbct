# coding: utf-8
class SchemaCollocazioniCentrale < ActiveRecord::Base
  self.table_name='schema_collocazioni_centrale'

  def sql_for_update_centrale_locations
    conditions = []

    if !scaffale.nil?
      from,to=scaffale.split('-')
      conditions << (to.nil? ? "scaffale = #{from}" : "scaffale between #{from} and #{to}")
    end
    if !palchetto.nil?
      if (palchetto =~ /^~/) or (palchetto =~ /^IN\(/)
        conditions << "secondo_elemento #{palchetto}"
      else
        conditions << "secondo_elemento='#{palchetto}'"
      end
    end
    if !filtro_colloc.nil?
      conditions << "collocazione #{filtro_colloc}"
    end
    c = conditions.join(' and ')
    # puts "#{self.id} update clavis.centrale_locations set piano='#{piano}' where #{c};"
    puts "update clavis.centrale_locations set piano='#{piano}' where #{c};"
  end

  def self.trova_piano(collocazione)
    puts "trovo il piano per la collocazione #{collocazione}"
    return nil if collocazione.strip.blank?
    scaffale,palchetto,catena = collocazione.split('.')
    puts "scaffale: #{scaffale}"
    puts "palchetto: #{palchetto}"
    int_scaffale=scaffale.to_i

    retval='__non assegnato__'
    if int_scaffale!=0
      puts "SCAFFALE NUMERICO"
      sql1=%Q{select * from #{self.table_name} where scaffale='#{scaffale}'}
      sql2=%Q{select * from #{self.table_name} where scaffale ~ '-' and #{scaffale} between
             split_part(scaffale,'-',1)::integer and split_part(scaffale,'-',2)::integer}
      sql="#{sql1} \n UNION #{sql2} order by id;"
      puts sql
      tuples=self.connection.execute(sql).to_a
      tuples.each do |r|
        puts r.inspect
        s_from,s_to=r['scaffale'].split('-')
        puts "s_from: #{s_from}"
        puts "s_to: #{s_to}"
        s_to=s_from if s_to.blank?
        next if !int_scaffale.between?(s_from.to_i,s_to.to_i)
        puts "procedo: #{r.inspect}"
        sql="select piano from #{self.table_name} where id=#{r['id']}"
        if !r['palchetto'].blank?
          if (r['palchetto'] =~ /^\w$/) == 0
            puts "lettera palchetto: #{r['palchetto']}"
            sql += " AND '#{palchetto}'='#{r['palchetto']}'"
          else
            puts "espressione palchetto: #{r['palchetto']}"
            sql += " AND '#{palchetto}' #{r['palchetto']}"
          end
        end
        puts sql
        res=self.connection.execute(sql)
        next if res.ntuples==0
        puts "trovato: #{res.first['piano']}"
        retval=res.first['piano']
      end
    else
      puts "Scaffale non numerico: #{scaffale}"
      sql = "select * from #{self.table_name} where scaffale is null and filtro_colloc notnull order by id"
      puts sql
      tuples=self.connection.execute(sql).to_a
      tuples.each do |r|
        #puts r.inspect
        #puts "filtro collocazione: #{r['filtro_colloc']}"
        extra_cond = []
        extra_cond << "'#{r['palchetto']}' = '#{palchetto}'" if !r['palchetto'].nil?
        extra_cond << "#{r['scaffale']} = #{scaffale}" if (int_scaffale!=0 and !r['scaffale'].nil?)
        extra_cond = extra_cond!=[] ? "AND #{extra_cond.join(' AND ')}" : ''
        sql="select '#{r['piano']}' as piano where '#{collocazione}' #{r['filtro_colloc']} #{extra_cond}"
        puts sql
        res=self.connection.execute(sql)
        next if res.ntuples==0
        puts "trovato: #{res.first['piano']}"
        retval=res.first['piano']
      end
    end
    retval
  end
end
