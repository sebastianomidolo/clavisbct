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
    'turbomarcauthority_cache',
    'CachedUserData',
    'Post',
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
        l.sub! ' unsigned',''
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
        if !(/FULLTEXT KEY/ =~ l).nil?
          next
        end
        if !(idx=/COMMENT '/ =~ l).nil?
          # puts "ATTENZIONE da carattere #{idx} #{l}"
          l=l[0..idx-1]
          # puts "DIVENTA #{l}"
        end
        if !(/ enum\(/ =~ l).nil?
          attr << "#{l.split.first} text"
          next
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

    def mysql_dng_dbdump_parse(outdir, force=false)
      filename = self.actual_dng_sql_dumpfile
      dbschema = 'import_dng'
      semaphore=File.join(outdir,'_done')
      if File.exists?(semaphore)
        if force==true
          File.delete(semaphore)
        else
          puts "File #{semaphore} esiste e non eseguo mysql_dng_dbdump_parse"
          return
        end
      end
      puts "leggo il file dump dng mysql #{filename} - schema postgresql: #{dbschema} e scrivo in #{outdir}"
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
              puts "#{Time.now} dest_filename: #{dest_filename}..."
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
            fdout.write(sql.gsub("'0000-00-00 00:00:00'",'NULL'))
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
      raise "non utilizzare create_pgdump, usare invece pg_tables_backup"
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
      raise "non utilizzare restore_pgdump, usare invece pg_tables_restore"
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

    def cmd_exec(cmd,quiet=true)
      puts "#{Time.now} START #{cmd}" if quiet==false
      Kernel.system(cmd)
      puts "#{Time.now} STOP #{cmd}" if quiet==false
    end

    def delete_semaphore(dir)
      semaphore=File.join(dir,'_done')
      File.delete(semaphore) if File.exists?(semaphore)
    end

    def uncompress_clavis_sql_dumpfile
      return false if File.exists?(self.actual_sql_dumpfile)
      cmd = "bunzip2 -k -c #{self.clavis_sql_dumpfile} > #{self.actual_sql_dumpfile}"
      self.cmd_exec(cmd)
      true
    end

    def uncompress_dng_sql_dumpfile
      return false if File.exists?(self.actual_dng_sql_dumpfile)
      cmd = "bunzip2 -k -c #{self.clavis_dng_sql_dumpfile} > #{self.actual_dng_sql_dumpfile}"
      self.cmd_exec(cmd)
      true
    end

    def clavis_sql_dumpfile
      config = Rails.configuration.database_configuration
      config[Rails.env]["clavis_sql_dumpfile"]
    end

    def clavis_dng_sql_dumpfile
      config = Rails.configuration.database_configuration
      config[Rails.env]["clavis_dng_sql_dumpfile"]
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

    def actual_dng_sql_dumpfile
      dirname=File.dirname self.clavis_dng_sql_dumpfile
      date=File.ctime(self.clavis_dng_sql_dumpfile).to_date
      # Il backup si riferisce al giorno precedente:
      date -= 1
      d = "%02d" % date.day
      m = "%02d" % date.month
      y = "%04d" % date.year
      bn = File.basename(self.clavis_dng_sql_dumpfile).split('.').first
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
        self.cmd_exec(cmd, quiet=true)
        cmd = "#{self.pgdump_bin} -U #{self.username} #{self.dbname} --table='#{dbschema}.#{t['tablename']}' --data-only --disable-trigger | sed '/search_path/d' > #{File.join(outdir, t['tablename'])}.sql"
        self.cmd_exec(cmd, quiet=true)
      end
    end

    def pg_tables_restore(fromschema, toschema, dirname)
      db=self.dbname
      user=self.username
      psql = self.psql_bin

      sql = %Q{select tablename from pg_tables where schemaname='#{toschema}' and not tablename ~ '^_'}
      puts "sql: #{sql}"
      tables=Hash.new
      self.connection.execute(sql).each do |t|
        # cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'set search_path to #{toschema}; truncate #{toschema}.#{t['tablename']}' -f #{File.join(dirname, t['tablename'])}.sql"
        # self.cmd_exec(cmd)
        # puts "in schema #{toschema} esiste tabella #{t['tablename']}"
        tables[t['tablename']] = true
      end

      puts "Recupero tabelle dallo schema #{fromschema} allo schema #{toschema} dalla dir #{dirname}"
      Dir.glob(File.join(dirname, "create_table_*.sql")).sort.each do |f|
        fn=File.basename(f).split('.').first
        if ( fn =~ /^create_table_(.*)/ ) == 0
          tablename=$1
          data = "#{File.join(File.dirname(f), tablename)}.sql"

          if tables[tablename].nil?
            puts "#{tablename}: non esiste e va creata in schema #{toschema} da in #{f}"
            cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'set search_path to #{toschema}' -f #{f}"
            self.cmd_exec(cmd)
          end
          # puts "#{tablename}: recupero dati da #{data}"
          cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'set search_path to #{toschema}' -c 'truncate #{tablename}' -f #{data}"
          puts cmd
          self.cmd_exec(cmd)
        end
      end
      return
    end

    def drop_schema_import
      dbschema = 'import'
      db=self.dbname
      user=self.username
      psql = self.psql_bin
      cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'drop schema if exists #{dbschema} cascade;'"
      self.cmd_exec(cmd)
    end

    def drop_schema_dng_import
      dbschema = 'import_dng'
      db=self.dbname
      user=self.username
      psql = self.psql_bin
      cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'drop schema if exists #{dbschema} cascade;'"
      puts cmd
      self.cmd_exec(cmd)
    end

    
    def insert_into_postgresql(sourcedir,force=false)
      dbschema = 'import'
      db=self.dbname
      user=self.username
      psql = self.psql_bin


      # semaphore=File.join(outdir,'_done')
      # if File.exists?(semaphore)
      #   if force==true
      #     File.delete(semaphore)
      #   else
      #     puts "File #{semaphore} esiste e non eseguo mysql_dbdump_parse"
      #     return
      #   end
      # end

      
      self.drop_schema_import if force==true

      sql = "select schema_name from information_schema.schemata where schema_name = '#{dbschema}'"
      if self.connection.execute(sql).count==1
        puts "Schema #{dbschema} esiste, usare force=true per cancellarlo e ricrearlo da zero"
        return
      end
      puts "Leggo da #{sourcedir} e creo schema #{dbschema}"
      cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'create schema #{dbschema}'"
      Kernel.system(cmd)

      Dir.glob(File.join(sourcedir, "*.sql")).sort.each do |f|
        cmd="#{psql} --no-psqlrc --quiet -d #{db} #{user}  -f #{f}"
        tab=File.basename(f)
        puts "#{Time.now} START INSERT INTO #{tab}"
        Kernel.system(cmd)
        puts "#{Time.now} STOP  INSERT INTO #{tab}"
      end

      # File.write(semaphore, 'ok')
      
    end

    def insert_dng_into_postgresql(sourcedir,force=false)
      dbschema = 'import_dng'
      db=self.dbname
      user=self.username
      psql = self.psql_bin

      self.drop_schema_dng_import if force==true

      sql = "select schema_name from information_schema.schemata where schema_name = '#{dbschema}'"
      if self.connection.execute(sql).count==1
        puts "Schema #{dbschema} esiste, usare force=true per cancellarlo e ricrearlo da zero"
        return
      end
      puts "Leggo da #{sourcedir} e creo schema #{dbschema}"
      cmd = "#{psql} --no-psqlrc --quiet -d #{db} #{user} -c 'create schema #{dbschema}'"
      Kernel.system(cmd)

      Dir.glob(File.join(sourcedir, "*.sql")).sort.each do |f|
        cmd="#{psql} --no-psqlrc --quiet -d #{db} #{user}  -f #{f}"
        tab=File.basename(f)
        puts "#{Time.now} START INSERT INTO #{tab}"
        cmd_exec(cmd, quiet=true)
        puts "#{Time.now} STOP  INSERT INTO #{tab}"
      end
    end
    
    def connection
      ActiveRecord::Base.connection
    end

    def dbname
      config = Rails.configuration.database_configuration
      config[Rails.env]["database"]
    end

    def username
      config = Rails.configuration.database_configuration
      config[Rails.env]["username"]
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
      scripts = ['create_view_super_items',
                 'create_super_items',
                 'patch_super_items',
                 'create_view_discardable_items',
                 'create_discardable_items',
                 'topografico',
                ]

      
      scripts = ['functions',
                 'view_digitalizzati',
                 'clean_data',
                 'indexes',
                 'create_collocazioni',
                 'support_tables',
                 'create_view_super_items',
                 'create_super_items',
                 'patch_super_items',
                 'create_current_super_items',
                 'create_view_discardable_items',
                 'create_discardable_items',
                 'topografico',
                ]

      scripts.each do |fname|
        sf=File.join(Rails.root.to_s, 'extras', 'sql', 'import', "#{fname}.sql")
        if !File.exists?(sf)
          puts "File non esistente, salto: #{sf}"
          next
        end
        puts "#{Time.now} INIZIO script #{sf}"
        cmd="#{psql} --no-psqlrc -d #{db} #{user} -f #{sf}"
        # puts cmd
        cmd_exec(cmd)
        puts "#{Time.now} FINE   script #{sf}"
      end
    end

    def musicale_title(autore,titolo)
      # puts "autore: #{autore}"
      # puts "titolo: #{titolo}"
      autore='' if autore.nil?
      titolo='' if titolo.nil?
      
      autore.sub!(/^\r\n/,'')
      autore.gsub!("\r\n","; ")
      autore.gsub!("\t"," ")

      #autore.gsub!("\n","NEWLINE_AUTORE")
      #autore.gsub!("\r","CARRIAGE_RETURN_AUTORE")
      autore.gsub!(/\n|\r/,'')
      
      titolo.sub!(/^\r\n/,'')
      titolo.gsub!("\r\n","; ")
      titolo.gsub!("\t"," ")
      #titolo.gsub!("\n","NEWLINE_TITOLO")
      #titolo.gsub!("\r","CARRIAGE_RETURN_TITOLO")
      titolo.gsub!(/\n|\r/,'')
      #a = autore.split("\n").join(' ; ')
      #t = titolo.split("\n").join(' ; ')
      return "#{titolo} / #{autore}"
    end

    # Verifiche da fare:
    # select tipologia,count(*) from import group by 1 order by 1;

    # select i.id,i.tipologia,substr(i.collocazione,1,20) as collocazione,substr(titolo, 1, 60) as titolo from import i left join import.super_items si on (si.colloc_stringa = i.collocazione) where si is null ;
    
    def import_musicale(csvfile)
      csv = CSV.read(csvfile,{col_sep:';',encoding: "ISO8859-1"})
      outfile = "/tmp/musicale_import.csv"
      fd = File.open(outfile, "w")
      fd.write("DROP TABLE bm_audiovisivi.import;\n")
      sql = %Q{CREATE TABLE IF NOT EXISTS bm_audiovisivi.import(id integer PRIMARY KEY,
        tipologia text, collocazione text, titolo text, collana text);}
      fd.write("#{sql}\n")
      fd.write("TRUNCATE bm_audiovisivi.import;\n")
      fd.write("COPY bm_audiovisivi.import(id,tipologia,collocazione,titolo,collana) FROM STDIN;\n")

      puts "csv size: #{csv.size}"
      cnt = 0
      csv.each do |r|
        cnt += 1
        next if cnt==1
        #puts "r class #{r.class}: #{r.inspect}"
        #puts "cnt #{cnt} - collocazione = #{r[2]}"
        id_volume=r[0]
        tipologia=r[1].blank? ? 'MANCA' : r[1].squeeze.strip.downcase
        collocazione=r[2]
        collocazione="\\N" if collocazione.nil?
        collocazione.gsub!(' ', '')

        #collocazione.gsub!("\n","NEWLINE_COLLOCAZIONE")
        #collocazione.gsub!("\r","CARRIAGE_RETURN_COLLOCAZIONE")
        collocazione.gsub!(/\n|\r/,'')


        
        collana=r[12]
        if !collana.nil?
          #collana.gsub!("\n","NEWLINE_COLLANA")
          #collana.gsub!("\r","CARRIAGE_RETURN_COLLANA")
          collana.gsub!(/\n|\r/,'')
        end
        collana="\\N" if collana.nil?
        
        titolo = musicale_title(r[3],r[4])
        if id_volume.to_i == 0
          id_volume="\\N"
        end

        # titolo << ". - #{collana}" if !collana.blank?
        
        # puts "id_volume: #{id_volume}\ntitolo: #{titolo}\nautore: #{autore}\ncollocazione: #{collocazione}\n--\n"
        # puts "id_volume: #{id_volume}\ncollocazione: #{collocazione}\ntitolo: \"#{titolo}\""
        fd.write("#{id_volume}\t#{tipologia}\t#{collocazione}\t#{titolo}\t#{collana}\n")
        # break if cnt == 6
      end
      fd.write("\\.\n")
      fd.close
      puts "scritto su #{outfile}"
    end

  end

  class Clinic
    def sanitize_collocations(sql)
      "ok : #{sql}"
      res = []
      cnt = 0
      self.connection.execute(sql).each do |r|
        chng = []
        cnt += 1
        mid = r['manifestation_id'].to_i
        mid = nil if mid==0
        fc = mid.nil? ? '(fuori catalogo) ' : ''

        res << "\n-- #{r['siglabib']} #{fc} colloc_stringa: \"#{r['colloc_stringa']}\" - cc.primo: \"#{r['primo']}\" - cc.secondo: \"#{r['secondo']}\""
        if r['secondo'] =~ / /
          new_colloc = r['collocation'].sub(/\s+/,'.')
          res << "-- colloc: \"#{r['collocation']}\" diventa \"#{new_colloc}\""
          chng << "collocation = #{self.connection.quote(new_colloc)}" if new_colloc != r['collocation']
        else
          colloc = r['collocation']
          colloc.gsub!(/\/|\./, "")
          colloc = colloc.split
          new_section = colloc.shift
          new_colloc = colloc.join('.')
          res << "-- section: #{r['section']} --> '#{new_section}' - colloc: #{r['collocation']} --> '#{new_colloc}'"
          chng << "section = #{self.connection.quote(new_section)}" if new_section != r['section']
          chng << "collocation = #{self.connection.quote(new_colloc)}" if new_colloc != r['collocation']
        end
        next if chng==[]
        res << "UPDATE item set #{chng.join(',')} where item_id=#{r['item_id']};"
        next if mid.nil?
        res << "UPDATE turbomarc_cache set dirty = 1 where manifestation_id=#{mid};"
      end
      res << "\n-- Fine lavoro su #{cnt} items"
      res.join("\n")
    end

    def mv_serial_issues_and_items(sql)
      
      r=self.connection.execute(sql).first
      new_mid = r['new_manifestation_id']
      old_mid = r['old_manifestation_id']
      from = r['issue_year_from']
      to   = r['issue_year_to']
      old_tit=ClavisManifestation.find(old_mid).title
      res = %Q{
BEGIN;
UPDATE issue set manifestation_id=#{new_mid} where manifestation_id=#{old_mid}
     and issue_year between '#{from}' and '#{to}';
UPDATE item set manifestation_id=#{new_mid} where manifestation_id=#{old_mid}
     and issue_year between '#{from}' and '#{to}';
UPDATE turbomarc_cache set dirty = 1 where manifestation_id=#{old_mid};
UPDATE turbomarc_cache set dirty = 1 where manifestation_id=#{new_mid}; 
ROLLBACK;
      }
    end
    
    def connection
      ActiveRecord::Base.connection
    end
  end


end
