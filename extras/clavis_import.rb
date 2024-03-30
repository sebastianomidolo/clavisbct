# coding: utf-8
module ClavisImport
  SKIP_TABLES=[
    'address',
    'changelog',
    'clavis_seq',
    'dng_blog_comment',
    'dng_blog_post',
    'dng_bmgroup',
    'dng_bookmark',
    'dng_reader_review',
    'dng_support',
    'dng_user_tag',
    'item_ok_old',
    'itemped',
    'patron_action',
    'patron_property',
    'patron_wallet',
    'query_log',
    'turbomarc_cache',
    'turbomarcauthority_cache'
  ]

  class Import

    def sql_for_table_create(msql, dbschema)
      tablename=msql.first.split[2].gsub("\`",'')
      return nil if SKIP_TABLES.include?(tablename) or tablename =~ /^_/
      msql.shift; msql.pop
      attr=[]
      msql.each do |l|
        l.strip!
        next if !(/^UNIQUE KEY/ =~ l).nil?
        next if !(/^KEY/ =~ l).nil?
        next if !(/^CONSTRAINT/ =~ l).nil?
        l.sub! /,$/,''
        l.sub! /USING BTREE/,''
        l.sub! /text mb3/,'text'
        l.sub! /COLLATE utf8_unicode_ci/,''
        l.sub! /COLLATE utf8_general_ci/,''
        l.sub! 'CHARACTER SET utf8mb3', ''
        l.sub! 'CHARACTER SET utf8', ''
        l.sub! /longtext/,'text'
        l.sub! ' mb3 ',''
        l.sub! /float/,'numeric'
        l.sub! /mediumtext/,'text'
        l.gsub!("\`",'"')
        l.sub!('datetime','timestamp')
        l.sub!('tinyint(1)','smallint')
        l.sub!('tinyint','smallint')
        l.sub! /tinyint\(.*\)/,'integer'
        l.sub! /bigint\(.*\)/,'integer'
        l.sub! /int\(.*\)/,'integer'
        if !(/AUTO_INCREMENT/ =~ l).nil?
          attr << "#{l.split.first} SERIAL"
          next
        end
        if !(idx=/COMMENT '/ =~ l).nil?
          # puts "ATTENZIONE da carattere #{idx} #{l}"
          l=l[0..idx-1]
          # puts "DIVENTA #{l}"
        end
        attr << l
      end
      [tablename,%Q{CREATE TABLE #{dbschema}."#{tablename}" (\n#{attr.join(",\n")}\n);}]
    end

    def sql_for_table_insert(msql, dbschema)
      return nil if (i=/ VALUES /=~msql).nil?
      tablename=msql [12..i-1].gsub("\`",'')
      return nil if SKIP_TABLES.include?(tablename) or tablename =~ /^_/
      msql.slice!(0,i)
      msql.gsub!("\\'", "''")
      msql.gsub!('\"', '"')
      msql.gsub!('\n', '')
      [tablename,%Q{INSERT INTO #{dbschema}."#{tablename}"#{msql}}]
    end

    def mysql_dbdump_parse(outdir, force=false)
      filename = self.actual_sql_dumpfile
      dbschema = 'import'
      semaphore=File.join(outdir,'_done')
      if File.exists?(semaphore)
        if force==true
          File.delete(semaphore)
        else
          puts "File #{semaphore} esiste e non eseguo mysql_dbdump_parse"
          return
        end
      end
      puts "leggo il file dump mysql #{filename} - schema postgresql: #{dbschema} e scrivo in #{outdir}"
      fd = File.new(filename, "r")
      cnt=0
      insert_count = 0
      tabledef=[]
      prec_filename=''
      tabledef_sql=nil
      fdout=nil
      fd.each_line do |line|
        cnt+=1
        if !(i=/^CREATE TABLE / =~ line).nil?
          # puts "create table (offset #{i}): #{line[i..(i+80)]}"
          tabledef << line.chomp
          next
        end
        if tabledef.size!=0
          tabledef << line.chomp
          if !(/^\) / =~ line).nil?
            tabname,tabledef_sql=sql_for_table_create(tabledef, dbschema)
            tabledef=[]
          end
        end

        if !(i=/^INSERT INTO / =~ line).nil?
          tabname,sql=sql_for_table_insert(line.chomp, dbschema)
          if !sql.nil?
            output_filename="#{tabname}.sql"
            if output_filename!=prec_filename
              if !fdout.nil?
                fdout.close
                fdout = nil
                puts "#{Time.now} #{insert_count-1} lines"
              end
              dest_filename = File.join(outdir,output_filename)
              insert_count = 1
              puts "#{Time.now} #{dest_filename}..."
              fdout=File.open(dest_filename,"w")
              fdout.write("-- File prodotto il #{Time.now} a partire da #{filename}\n");
              fdout.write(setsqlvars)
              if tabledef_sql.nil?
                puts "Errore per #{output_filename}"
              else
                fdout.write("#{tabledef_sql}\n")
              end
            end
            prec_filename=output_filename
            tabledef_sql=nil
            next if fdout.nil?
            fdout.write(sql)
            fdout.write("\n")
            # puts "insert line #{insert_count} per table #{tabname}"
            insert_count += 1
          end
        end
      end
      if !fdout.nil?
        fdout.close
        puts "#{Time.now} - ok #{insert_count-1} lines (ultima tabella del dump)"
      end
      fd.close
      File.write(semaphore, 'ok')
    end

    def create_pgdump(dump_file,force=false)
      dbschema='import'
      if force==true and File.exists?(dump_file)
        File.delete(dump_file)
      end
      if File.exists?(dump_file)
        puts "file #{dump_file} esiste e non procedo con create_dump - usare force=true per forzare l'esecuzione"
        return
      end
      # Effettuo il dump di dbschema, eliminando le linee che si riferiscono allo schema stesso, in modo da ottenere un dump pulito
      # e quindi riutilizzabile in una altro schema (cosa che viene fatta da restore_dump)
      cmd = "#{self.pgdump_bin} -U #{self.username} #{self.dbname} --schema=#{dbschema} | sed '/search_path\\|CREATE SCHEMA\\|ALTER SCHEMA/d' > #{dump_file}"
      self.cmd_exec(cmd)
    end

    def restore_dump(dump_file,dest_schema,force=false)
      if force==true
        sql = "DROP SCHEMA if exists #{dest_schema} CASCADE;"
        puts sql
        self.connection.execute(sql)
      end
      sql = "SELECT true FROM pg_catalog.pg_tables where schemaname='#{dest_schema}' and tablename='_import_ok'"
      puts sql
      if self.connection.execute(sql).count==1
        puts "restore_dump già eseguito, usare force=true per forzare l'esecuzione"
        return
      end
      rfile = '/tmp/run_restore.sql'
      File.write(rfile, "create schema if not exists #{dest_schema};\nset search_path to #{dest_schema};\n\\i #{dump_file}")
      puts File.read(rfile)
      cmd = "#{self.psql_bin} --no-psqlrc --quiet -d #{self.dbname} #{self.username} -f #{rfile}"
      self.cmd_exec(cmd)
      sql = "create table #{dest_schema}._import_ok()"
      self.connection.execute(sql)
    end

    def cmd_exec(cmd)
      puts "#{Time.now} START #{cmd}"
      Kernel.system(cmd)
      puts "#{Time.now} STOP #{cmd}"
    end

    def uncompress_clavis_sql_dumpfile
      return if File.exists?(self.actual_sql_dumpfile)
      cmd = "bunzip2 -k -c #{self.clavis_sql_dumpfile} > #{self.actual_sql_dumpfile}"
      self.cmd_exec(cmd)
    end

    def clavis_sql_dumpfile
      config = Rails.configuration.database_configuration
      config[Rails.env]["clavis_sql_dumpfile"]
    end

    def actual_sql_dumpfile
      dirname=File.dirname self.clavis_sql_dumpfile
      date=File.ctime(self.clavis_sql_dumpfile).to_date
      # Il backup si riferisce al giorno precedente:
      date -= 1
      d = "%02d" % date.day
      m = "%02d" % date.month
      y = "%04d" % date.year
      bn = File.basename(self.clavis_sql_dumpfile).split('.').first
      File.join(dirname, "#{bn}_#{y}-#{m}-#{d}.sql")
    end

    def rebuild_clavis_schema(dbschema)
      cmd=%Q{#{self.psql_bin} -c "BEGIN" -c "DROP SCHEMA #{dbschema} CASCADE" -c "COMMIT" -c "CREATE SCHEMA clavis" #{self.dbname} #{self.username}}
      puts "SIMULO #{cmd}"
      puts "DISABILITATO di default"
      # Kernel.system(cmd)
    end

    def pg_tables_backup(dbschema,outdir)
      sql = %Q{select * from pg_tables where schemaname='#{dbschema}' order by tablename}
      self.connection.execute(sql).each do |t|
        cmd = "#{self.pgdump_bin} -U #{self.username} #{self.dbname} --table='#{dbschema}.#{t['tablename']}' --schema-only | sed '/search_path/d' > #{File.join(outdir, 'create_table_'+t['tablename'])}.sql"
        self.cmd_exec(cmd)
        cmd = "#{self.pgdump_bin} -U #{self.username} #{self.dbname} --table='#{dbschema}.#{t['tablename']}' --data-only --disable-trigger | sed '/search_path/d' > #{File.join(outdir, t['tablename'])}.sql"
        self.cmd_exec(cmd)
      end
    end

    def pg_tables_restore(fromschema, toschema, dirname)
      db=self.dbname
      user=self.username
      psql = self.psql_bin
      puts "Recupero tabelle dallo schema #{fromschema} allo schema #{toschema} dalla dir #{dirname}"
      Dir.glob(File.join(dirname, "*.sql")).sort.each do |f|
        tablename=File.basename(f).split('.').first
        puts "table: #{tablename} da file #{f}"
      end

      return
      sql = %Q{select tablename from pg_tables where schemaname='#{toschema}' and not tablename ~ '^_' order by tablename}
      self.connection.execute(sql).each do |t|
        cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'set search_path to #{toschema}; truncate #{toschema}.#{t['tablename']}' -f #{File.join(dirname, t['tablename'])}.sql"
        self.cmd_exec(cmd)
      end
    end

    def insert_into_postgresql(sourcedir,force=false)
      dbschema = 'import'
      db=self.dbname
      user=self.username
      psql = self.psql_bin

      if force==true
        cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'drop schema if exists #{dbschema} cascade;'"
        Kernel.system(cmd)
      end

      sql = "select schema_name from information_schema.schemata where schema_name = '#{dbschema}'"
      if self.connection.execute(sql).count==1
        puts "Schema #{dbschema} esiste, usare force=true per procedere comunque"
        return
      end
      puts "Leggo da #{sourcedir} nello schema #{dbschema}"
      cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'create schema #{dbschema}'"
      Kernel.system(cmd)
      Dir.glob(File.join(sourcedir, "*.sql")).sort.each do |f|
        cmd="#{psql} --no-psqlrc --quiet -d #{db} #{user}  -f #{f}"
        tab=File.basename(f)
        puts "#{Time.now} START INSERT INTO #{tab}"
        Kernel.system(cmd)
        puts "#{Time.now} STOP  INSERT INTO #{tab}"
      end
    end

    def connection
      ActiveRecord::Base.connection
    end

    def dbname
      config = Rails.configuration.database_configuration
      dbname=config[Rails.env]["database"]
    end

    def username
      config = Rails.configuration.database_configuration
      username=config[Rails.env]["username"]
    end

    def psql_bin
      '/usr/bin/psql'
    end

    def pgdump_bin
      '/usr/bin/pg_dump'
    end

    def insert_files_dir
      config = Rails.configuration.database_configuration
      source=config[Rails.env]["clavis_datasource"]
    end

    def setsqlvars
      %Q{SET standard_conforming_strings TO false;
SET backslash_quote TO 'safe_encoding';
SET escape_string_warning TO false;
}
    end


    def sql_scripts()
      db=self.dbname
      user=self.username
      psql = self.psql_bin
      ['collocazione',
       'view_prestiti',
       'view_digitalizzati',
       'setup',
       'ricollocazioni',
       'merge_tobi',
       'views',
       'export_bioicon',
       'dinotola'
      ].each do |fname|
        sf=File.join(Rails.root.to_s, 'extras', 'sql', 'import', "#{fname}.sql")
        if !File.exists?(sf)
          puts "Non esiste: #{sf}"
          next
        end
        cmd="#{psql} --no-psqlrc -d #{db} #{user} -f #{sf}"
        # puts cmd
        cmd_exec(cmd)
        # puts "import_from_clavis, inizio esecuzione #{cmd}: #{Time.now}"
        # puts "import_from_clavis, fine esecuzione #{cmd}: #{Time.now}"
      end
    end

  end

end
