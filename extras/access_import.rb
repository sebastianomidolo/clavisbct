# lastmod  9 agosto 2012
# lastmod  8 agosto 2012
# lastmod  7 agosto 2012 : NB sviluppo spostato su questa macchina linux64bit da tobi
# lastmod  6 agosto 2012
# lastmod 31 luglio 2012
# lastmod 30 luglio 2012

module AccessImport
  require 'csv'

  class AccessFile
    
    attr_reader :fields

    def initialize(filename,connection=nil)
      @tables=nil
      @schema={}
      @fields={}
      if connection.nil?
        @connection=ActiveRecord::Base.connection
      else
        @connection=connection
      end

      # puts "ok access file: #{filename}"
      @filename=filename
      self.tables
      self.schema
      true
    end

    def pino
      puts "connection: #{@connection}"
    end

    def pg_schema
      self.sanifica_nome(File.basename(@filename, '.*'))
    end

    def pg_tablename(access_tablename)
      "#{self.pg_schema}.#{self.sanifica_nome(access_tablename)}"
    end

    def drop_pg_table(access_tablename, connection=nil)
      connection=@connection if connection.nil?
      sql=%Q{BEGIN; DROP TABLE #{self.pg_tablename(access_tablename)}; COMMIT;}
      begin
        connection.execute(sql)
      rescue
        puts "Errore intrappolato: #{$!}"
        connection.execute("ROLLBACK")
      end
    end
    def create_pg_table(access_tablename, connection=nil)
      connection=@connection if connection.nil?
      sql=%Q{BEGIN;#{self.pg_tabledef(access_tablename)};COMMIT;}
      # puts "sql: #{sql}"
      begin
        connection.execute(sql)
      rescue
        puts "Errore intrappolato: #{$!}"
        connection.execute("ROLLBACK")
      end
    end
    def pg_tabledef(access_tablename)
      @schema[self.pg_tablename(access_tablename).to_sym]
    end

    def create_pg_schema
      return if @connection.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name='#{self.pg_schema}'").ntuples==1
      @connection.execute("CREATE SCHEMA #{self.pg_schema}")
    end

    def tables
      return @tables if !@tables.nil?
      tempdir = File.join(Rails.root.to_s, 'tmp')
      tf = Tempfile.new("mdbtools",tempdir)
      Kernel.system("mdb-tables -d '|' #{@filename} > #{tf.path}")
      tf.rewind;data=tf.read;tf.close(true)
      @tables=[]
      @tables=data.split('|').collect {|x| x=="\n" ? nil : x}
      @tables=@tables.compact.sort.uniq
    end

    def sql_outfilename
      "mdb_export_#{self.pg_schema}.sql"
    end

    def sql_copy(access_tablename)
      output_filename=self.sql_outfilename
      outfd=File.open(output_filename, 'a')
      tname=self.pg_tablename(access_tablename)
      puts "#{access_tablename} => #{tname}"
      tempdir = File.join(Rails.root.to_s, 'tmp')
      tf = Tempfile.new("mdbtools",tempdir)
      cmd=%Q{mdb-export -I postgres -R"__RECSEP__" #{@filename} "#{access_tablename}" > #{tf.path}}
      # puts cmd
      Kernel.system(cmd)
      tf.rewind;data=tf.read;tf.close(true)

      # puts "data.size: #{data.size}"
      # puts data

      return '' if data.size==0
      data.gsub!("\r\n", '; ')
      data.gsub!("\t", ' ')
      data.gsub!("\\", ' ')
      cnt=0
      res=[]
      data.split('__RECSEP__').each do |r|
        r.gsub!("\n", ' ')
        # puts "r: #{r}"
        ar=r.split(") VALUES (")
        if ar.size!=2
          puts "Errore nei dati linea #{cnt}: #{r}"
          next
        end
        fields,values=ar
        if cnt==0
          flds='a'
          fields=fields[fields.index('(')+1..fields.size]
          fields.gsub!('"','')
          puts fields.inspect
          # cells=CSV::Reader.parse(fields).first.collect {|i| i.strip}
          cells=CSV.parse(fields).first.collect {|i| i.strip}
          flds=cells.collect {|x| self.sanifica_nome(x)}
          # puts flds.inspect
          # res << "TRUNCATE #{tname};SET CLIENT_ENCODING=latin1;"
          res << "TRUNCATE #{tname};SET CLIENT_ENCODING=utf8;"
          res << "COPY #{tname} (#{flds.join(',')}) FROM stdin;"
        end
        #values="1,2,3"
        values.sub!(/\);$/,'')
        # puts "values: #{values}"
        # cells=CSV::Reader.parse(values).first.collect {|i| i=='NULL' ? "\\N" : i.strip}
        cells=CSV.parse(values).first.collect {|i| i=='NULL' ? "\\N" : i.strip}
        res << cells.join("\t")
        cnt+=1
      end
      res << "\\.\n"
      res=res.join("\n")
      i=outfd.write(res)
      outfd.close
      return i
    end

    def sanifica_nome(s)
      # puts "s: #{s}"
      s.gsub!(/\[|\]/,'')
      s=s.downcase.gsub(' ', '_')
      # s=Iconv.conv('UTF-8//IGNORE', 'ASCII', s)
      s.gsub!(/[-\/]/, '_')
      s.gsub!("+", '_plus_')
      s.gsub!("/", '_')
      s
    end

    def schema
      # puts "inizializzo schema"
      def print_table_definition(t,f)
        %Q{CREATE TABLE #{t} (\n\t#{f.join(",\n\t")}\n);\n}
      end
      def fields_definition(t,f)
        f
      end

      # puts "@schema.class: #{@schema.class}"

      return @schema if @schema.size>0

      tempdir = File.join(Rails.root.to_s, 'tmp')
      tf = Tempfile.new("mdbtools",tempdir)
      cmd="mdb-schema #{@filename} > #{tf.path}"
      # puts cmd
      Kernel.system(cmd)
      tf.rewind;data=tf.read;tf.close(true)
      # puts "lettura schema per #{@filename}"
      opened=false; table_name='';fields=[]
      data.each_line do |l|
        l.strip!
        next if (/^--/ =~ l) or
          (/^relationships are not supported/ =~ l) or
          l.blank? or
          (/^DROP TABLE/ =~ l)
        # puts l
        if !opened
          if (/^CREATE TABLE/ =~ l)
            opened=true; fields=[]
            table_name=self.pg_tablename(l[13..1000])
            # puts "table name: '#{table_name}'"
          end
        else
          if l==');'
            opened=false;
            @schema[table_name.to_sym]=print_table_definition(table_name, fields)
            @fields[table_name.to_sym]=fields_definition(table_name, fields)
            next
          end
          next if l=='('
          l.downcase!
          # puts "dato tabella: #{l}"
          dt=l.split("\t")
          field_name=self.sanifica_nome(dt.first)

          # Aggiustamento tipo di campo
          field_type=dt.last.sub(/,$/,'')
          field_type.sub!("text", 'char')
          field_type='integer' if /long integer/ =~ field_type
          field_type='double precision' if /double/ =~ field_type
          field_type='text' if /memo\/hyperlink/ =~ field_type
          field_type='text' if /unknown/ =~ field_type

          # Sarebbe questo:
          field_type='date' if /datetime/ =~ field_type
          # Ma per evitare errori presenti nei dati:
          # field_type='text' if /datetime/ =~ field_type


          # valutare come trattare il campo currency di access
          field_type='numeric(16,2)' if /currency/ =~ field_type
          # field_type='text' if /currency/ =~ field_type


          field_type='text' if /char/ =~ field_type

          field_type='bytea' if /ole/ =~ field_type

          # field_type.sub!("char", "varchar")

          # Solo per fargli digerire i dati:
          # field_type.sub!("boolean", "text")
          # field_type.sub!("integer", "text")

          # puts "nome campo: '#{field_name}' - tipo: '#{field_type}'"
          fields << "#{field_name} #{field_type}"
        end
      end
      @schema
    end
  end

end
