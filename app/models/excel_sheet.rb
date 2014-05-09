class ExcelSheet < ActiveRecord::Base
  belongs_to :excel_file

  def column_heading(column)
    Psych.load(self.column_headings)[column]
  end
  def to_label
    "#{self.excel_file.basename}(#{self.excel_file.id}) => #{self.sheet_name} (#{self.id})"
  end

  def sync
    ef=self.excel_file
    mtime=File.mtime(ef.file_name)
    if mtime > ef.updated_at
      begin
        self.rebuild_table
        ef.updated_at=mtime
        ef.file_size=File.size(ef.file_name)
        ef.save if ef.changed?
      rescue
        puts "Errore: #{$!}"
      end
    end
  end

  def sql_count
    self.connection.execute("SELECT count(*) from #{self.sql_tablename}").first['count'].to_i
  end

  def sql_paginate(search_options={},options={:page=>1})
    qs=search_options[:qs]
    vn=search_options[:view_number].blank? ? nil : search_options[:view_number].to_i
    cols=self.sql_columns(vn)
    conditions=[]
    order=''

    if !qs.blank?
      qs.gsub!(/\(|\)|&/,' ')
      dtypes=self.data_types
      fields=[]
      cn=search_options[:column_number]
      if !cn.blank?
        fields << "#{cols[cn.to_i]}::text"
      else
        cols.each do |col|
          next if col=='excel_cell_row'
          fields << "#{col}::text"
        end
      end
      ts=self.connection.quote_string(qs.split.join(' & '))
      conditions << %Q{to_tsvector(#{fields.join(" || ' ' || ")}) @@ to_tsquery('english','#{ts}')}
    end
    # if !vn.nil? and cols[0]!='excel_cell_row'
    if !vn.nil?
      # conditions << "#{cols[1]} is not null"
      conditions << "#{cols[1]} !=''"
    end
    where=conditions.size==0 ? '' : "WHERE #{conditions.join(' AND ')}"
    order = "ORDER BY #{cols[1..3].join(',')}"
    sql=%Q{SELECT #{cols.join(',')} FROM #{self.sql_tablename} #{where} #{order}}
    # fd=File.open("/tmp/logfile.txt","w")
    # fd.write(sql)
    # fd.close
    ExcelSheet.paginate_by_sql(sql,options)
  end

  def sql_paginate_group_by(search_options,options={:page=>1})
    vn=search_options[:view_number].blank? ? nil : search_options[:view_number].to_i
    column=self.sql_columns(vn)[search_options[:group].to_i]
    where = search_options[:qs].blank? ? "#{column} IS NOT NULL" : "#{column} ~* #{self.connection.quote(search_options[:qs])}"
    if vn.class!=NilClass
      filter=sql_columns(vn).first
      where << " AND #{filter} IS NOT NULL"
    end
    sql=%Q{SELECT #{column} as col,count(*) FROM #{self.sql_tablename}
      WHERE #{where}
      GROUP BY #{column}
      ORDER BY #{column}}
    puts sql
    ExcelSheet.paginate_by_sql(sql,options)
  end

  def sql_tablename
    cfg=self.load_config
    if cfg[:tablename].nil?
      tname="table_#{self.id}_#{self.sheet_name.downcase.gsub(' ','_')}"
      self.tablename=nil
    else
      tname=cfg[:tablename]
      self.tablename=tname
    end
    self.save if self.changed?
    %Q{excel_files_tables.#{tname}}
  end

  def load_config
    cfg=self.excel_file.load_config
    x=cfg[:sheets_config][self.sheet_number]
    x.nil? ? {} : x
  end

  def postload_sql_exec
    x=self.load_config[:postload_sql_exec]
    return if x.nil?
    x.each do |s|
      sql=s.sub('replace_with_tablename', self.sql_tablename)
      sql=sql.sub('replace_with_excel_sheet_id', "#{self.id}")
      begin
        self.connection.execute(sql)
      rescue
        puts "error: #{$!}"
      end
    end
    dth=self.data_types
    a=self.sql_columns.delete_if do |c|
      next if c=='excel_cell_row'
      # puts "c: #{c} => #{dth[c].class}"
      dth[c].class==NilClass
    end
    self.columns=a
    self.save if self.changed?
  end

  def locate_headings(excel=nil)
    headings={:row=>1, :numcols=>100}
    puts self.excel_file.config_filename
    cfg=self.excel_file.load_config
    # puts "cfg #{cfg}"
    guess=false
    if !cfg[:sheets_config].nil?
      sc=cfg[:sheets_config][self.sheet_number]
      if sc.nil?
        guess=true
      else
        if sc[:headings].nil?
          guess=true 
        else
          headings=cfg[:sheets_config][self.sheet_number][:headings]
        end
      end
    else
      guess=true
    end
    if guess
      headings=self.guess_headings_from_sourcefile(excel)
      if headings.size>0
        if cfg[:sheets_config].nil?
          cfg[:sheets_config]={}
        end
        if cfg[:sheets_config][self.sheet_number].nil?
          cfg[:sheets_config][self.sheet_number]={}
        end
        cfg[:sheets_config][self.sheet_number][:headings]=headings
        self.excel_file.write_config(cfg)
      end
    end
    headings
  end
  def guess_headings_from_sourcefile(excel=nil)
    maxrows=20
    puts "sourcefile: #{self.excel_file.file_name}"
    excel=Roo::Excel.new(self.excel_file.file_name) if excel.nil?
    sheet=excel.sheet(self.sheet_number)
    cnt=0
    numcols=100
    (1..maxrows).each do |rn|
      cnt+=1
      data=sheet.row(rn).compact
      if data.size==sheet.row(rn).size
        numcols=data.size
        break
      end
    end
    cnt > 0 ? {:row=>cnt,:numcols=>numcols} : {}
  end

  def sql_columns(view_number=nil,excel=nil)
    # puts "entrato in sql_columns"
    if !self.columns.nil?
      @sql_columns=YAML.load(self.columns)
    else
      @sql_columns=['excel_cell_row']
      headings=self.locate_headings(excel)
      puts "headings: #{headings.inspect}"
      excel=Roo::Excel.new(self.excel_file.file_name) if excel.nil?
      sheet=excel.sheet(self.sheet_number)
      cnt=0
      sheet.row(headings[:row]).each do |c|
        # puts "#{cnt}: #{c}"
        cnt+=1
        @sql_columns << %Q{"#{self.normalize_column_name(c,cnt)}"}
        break if cnt>=headings[:numcols]
      end
      self.columns=@sql_columns
      self.save if self.changed?
    end
    if !view_number.nil?
      res=['excel_cell_row']
      self.views[view_number-1][:columns].each do |c|
        res << @sql_columns[c]
      end
      @sql_columns=res
    end
    @sql_columns
  end
  def normalize_column_name(s,cnt)
    return "Colonna #{cnt}" if s.class!=String
    s.gsub(/\n|\r/,' ').gsub('"',"'")
  end
  def sql_droptable
    sql="DROP TABLE #{self.sql_tablename}"
    puts "sql da eseguire:\n#{sql}"
    begin
      self.connection.execute(sql)
    rescue
      puts "Errore #{$!}"
    end
  end
  def sql_createtable(excel=nil)
    ar=[]
    cnt=0
    self.sql_columns(nil,excel).each do |c|
      cnt+=1
      if cnt==1 or c=='"manifestation_id"'
        ar << "#{c} integer"
      else
        ar << "#{c} text"
      end
    end
    return false if ar.size==0
    sql="CREATE TABLE #{self.sql_tablename} (#{ar.join(',')})"
    puts "sql da eseguire:\n#{sql}"
    begin
      self.connection.execute(sql)
    rescue
      puts "Errore #{$!}"
    end
  end

  def rebuild_table
    excel=self.excel_file.open_excel_file
    self.sql_droptable
    self.columns=nil
    self.sql_createtable(excel)
    self.save
    self.reload
    self.import_from_sourcefile(excel)
    self.postload_sql_exec
    self.alter_data_types
  end

  def load_row(row_id)
    sql=%Q{SELECT #{self.sql_columns.join(',')} FROM #{self.sql_tablename} WHERE excel_cell_row=#{row_id.to_i}}
    self.connection.execute(sql).first
  end

  def import_from_sourcefile(excel=nil)
    ef=self.excel_file
    dth=self.data_types
    puts "copy data from #{ef.file_name}"
    excel=Roo::Excel.new(ef.file_name) if excel.nil?
    sheet=excel.sheet(self.sheet_number)
    headings=self.locate_headings(excel)
    from = headings[:row]+1
    maxcol = headings[:numcols]

    sqlfile="/tmp/import_data_#{self.id}.sql"
    fdout=File.open(sqlfile,"w")
    puts "scrivo su #{sqlfile}"

    fdout.write(%Q{TRUNCATE TABLE #{self.sql_tablename};\n})
    cols=self.sql_columns
    fdout.write(%Q{COPY #{self.sql_tablename} (#{cols.join(',')}) FROM stdin;\n})

    (from..sheet.last_row).each do |rn|
      cnt=0
      data=[rn]
      sheet.row(rn).each do |d|
        cnt+=1
        # puts "d (#{cnt}) #{d} => #{cols[cnt]} => #{dth[cols[cnt]]}"
        if d.blank?
          d = dth[cols[cnt]]=='integer' ? "\\N" : ''
        else
          if d.class==Float
            intero=d.to_i
            d = intero!=0 ? intero : d.to_s
          else
            d=d.to_s.strip
            d.gsub!(/\n|\r/,'\r')
            d.gsub!(/\t/,' ')
          end
        end
        data << d
        break if cnt>=maxcol
      end
      fdout.write(%Q{#{data.join("\t")}\n})
    end
    fdout.write("\\.\n")
    fdout.close
    config = Rails.configuration.database_configuration
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username} -f #{sqlfile}"
    puts cmd
    Kernel.system(cmd)
  end

  def views
    return [] if self.load_config[:views].nil?
    self.load_config[:views]
  end

  def data_types
    schema,table=self.sql_tablename.gsub('"','').split('.')
    sql=%Q{SELECT column_name, data_type FROM information_schema.columns
            WHERE table_schema = '#{schema}' AND table_name='#{table}';
    }
    res={}
    self.connection.execute(sql).each do |r|
      key=%Q{"#{r['column_name']}"}
      res[key]=r['data_type']
    end
    res
  end

  def alter_data_types
    dth=self.data_types
    dth.each_pair do |col,v|
      if v=='text'
        # sql=%Q{UPDATE #{self.sql_tablename} SET #{col}=NULL WHERE #{col}=''}
        # self.connection.execute(sql)
      end
      ['date','integer','float'].each do |newtype|
        # puts "tipo di partenza per #{col}: #{v} candidato alla conversione da #{v} a #{newtype}"
        next if v==newtype or v!='text'

        # puts "procedo per #{col} da #{v} a #{newtype}"
        sql=%Q{ALTER table #{self.sql_tablename} ALTER COLUMN #{col} TYPE #{newtype} USING(#{col}::#{newtype})}
        if newtype=='date'
          ['DMY','YMD'].each do |datestyle|
            self.connection.execute("set datestyle to #{datestyle}")
            begin
              self.connection.execute(sql)
              break
            rescue
              # puts "conversione impossibile (datestyle #{datestyle})"
            end
          end
        else
          begin
            self.connection.execute(sql)
            break
          rescue
            # puts "conversione impossibile"
          end
        end
      end
    end
  end

end
