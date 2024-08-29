class TalkingBookDownload < ActiveRecord::Base
  self.table_name='libroparlato.downloads'
  belongs_to :talking_book, foreign_key:'title_id'

  attr_accessible :method, :http_status, :username, :http_path

  def self.tutti(params={})
    self.paginate_by_sql(self.sql_for_tutti(params), page:params[:page], per_page:500)
    
  end

  def self.generic_select(attr, params={})
    sql=%Q{select #{attr} as key,#{attr} as label, count(*) from #{TalkingBookDownload.table_name} where #{attr} notnull group by #{attr} order by #{attr}}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['count']})"
      res << [label,r['key']]
    end
    res
  end

  def self.sql_for_tutti(params={})
    dl = TalkingBookDownload.new(params[:talking_book_download])
    cond = []
    attrib=dl.attributes.collect {|a| a if not a.last.blank?}.compact
    attrib.each do |a|
      name,value=a
      case name
      when 'neverhappens'
      else
        value = self.connection.quote(value)
        cond << "#{name} = #{value}"
      end
    end
    cond = (cond.size == 0) ? '' : "WHERE #{cond.join(" AND ")}"
    sql=%Q{
      select d.*,tb.n as collocazione from #{TalkingBookDownload.table_name} d
         left join #{TalkingBook.table_name} tb on (tb.id=d.title_id)
              
            #{cond}
         order by date desc
    }
  end

  def TalkingBookDownload.update_from_log_opac(fname)
    sql = []
    File.readlines(fname).each do |line|
      logline = line.chomp
      line.gsub!(/\(record id: |\)/,'')
      date = line[0..18]
      a = line.split
      timezone = a[2]
      http_path = a[5]
      title_id = a[6].to_i
      user = a.last
      # opac_username=ClavisPatron.find(user_id).opac_username
      sql << "insert into libroparlato.downloads (method,username,date,timezone,title_id,http_path,logline) values ('OPAC','#{user}','#{date}','#{timezone}',#{title_id},'#{http_path}',#{self.connection.quote(logline)}) on conflict(logline) do nothing;"
    end
    sql << "update libroparlato.downloads d set username=p.opac_username from clavis.patron p where d.method='OPAC' and d.username ~ '^\\d+$'and p.patron_id=d.username::integer;\n"
    # puts sql.join("\n")
    self.connection.execute(sql.join("\n"))
    nil
  end

  
end
