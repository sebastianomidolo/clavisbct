# coding: utf-8
class ClavisLibrarian < ActiveRecord::Base
  self.table_name='clavis.librarian'
  self.primary_key = 'librarian_id'

  def iniziali
    status = self.activation_status=='1' ? 'attivo' : 'disattivato'
    "#{self.name[0]}#{self.lastname[0]} cat_level #{self.cat_level} - #{status}"
  end

  def to_label
    status = self.activation_status=='1' ? '' : '(non abilit. in Clavis)'
    "#{self.name} #{self.lastname} - cat_level #{self.cat_level} - #{status}"
  end

  def to_shortlabel
    status = self.activation_status=='1' ? '' : '(non abilit. in Clavis)'
    "#{self.name} #{self.lastname}"
  end

  def clavis_libraries
    sql = %Q{SELECT l.* FROM clavis.l_library_librarian ll join clavis.library l using(library_id) where librarian_id=#{self.id}}
    ClavisLibrary.find_by_sql(sql)
  end

  def clavis_sessions
    sql = "SELECT s.start_date,s.end_date,s.last_action_date,l.shortlabel,l.label,l.library_id
             FROM clavis.librarian_session s join clavis.library l on s.current_library_id = l.library_id
               WHERE librarian_id=#{self.id} ORDER BY start_date"
    self.connection.execute(sql).to_a
  end

  def working_time
    max_hours = 12
    max_seconds_per_day = 60*60*max_hours
    total_sec=0
    self.clavis_sessions.each do |r|
      next if r['last_action_date'].nil?
      seconds = r['last_action_date'].to_time - r['start_date'].to_time
      if seconds > max_seconds_per_day
        # Non calcolo le giornate con sessioni superiori alle "max_hours"
        # perché probabilmente si tratta di sessioni lasciate aperte
        # seconds = max_seconds_per_day
        # O meglio, calcolo convenzionalmente un'ora:
        seconds = max_seconds_per_day
        puts "Superate le ore giornaliere? #{r['start_date']} #{r['last_action_date']}"
      end
      total_sec += seconds
      # puts "Time.at: #{Time.at(seconds).utc.strftime('%H:%M')}"
    end
    (total_sec / 3600).to_i
  end

  def clavis_url
    ClavisLibrarian.clavis_url(self.id)
  end

  def ClavisLibrarian.tutti(params={})
    order = params[:order]=='alfa' ? 'cl.lastname,cl.name' : 'start_date desc,cl.lastname' 
    sql = %Q{select cl.librarian_id,cl.name,cl.lastname,substr(l.label,6) as library,
              most_recent_session.start_date from clavis.librarian cl join
            (select distinct on (librarian_id) * from clavis.librarian_session order by librarian_id, start_date desc)
        as most_recent_session
          on cl.librarian_id = most_recent_session.librarian_id
       join clavis.library l on  l.library_id=cl.default_library_id
       where cl.activation_status='1'
      order by #{order};}
    
    self.connection.execute(sql).to_a
  end

  def self.clavis_url(librarian_id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Library.LibrarianViewPage&id=#{librarian_id}"
  end

  def ClavisLibrarian.label_select
    sql = %Q{select l.shortlabel,cl.username,concat_ws(' ', cl.name,cl.lastname) as name,
              cl.librarian_id as key from clavis.librarian cl join clavis.library l on(l.library_id=cl.default_library_id) 
               left join public.users u on(u.email=cl.username)
                where u is null and cl.activation_status='1' and l.library_id>1 and l.shortlabel!=''
              order by cl.lastname,cl.name}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['name']} (#{r['shortlabel']} - #{r['username']})"
      res << [label,r['key']]
    end
    res
  end

  
end
