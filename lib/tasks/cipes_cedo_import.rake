# -*- mode: ruby;-*-

desc 'Importazione dati da dump base dati Cipes/CeDo'

# http://bctdoc.comperio.it/issues/254

task :cipes_cedo_import => :environment do
  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]

  sourcefile="/home/seb/tmp/cipes/dump_cipes_20151126.sql"
  outfile="/home/seb/tmp/cipes/cipes_postgresql.sql"
  SKIP_TABLES=[]

  def setsqlvars
    %Q{SET standard_conforming_strings TO false;
SET backslash_quote TO 'safe_encoding';
SET escape_string_warning TO false;
DROP SCHEMA cipes CASCADE;
CREATE SCHEMA cipes;
SET SEARCH_PATH TO cipes;
}
  end

  def converti_file(srcfile,outfile)

    fdo=File.open(outfile, 'w')

    do_create_table=lambda do |msql|
      tablename=msql.first.split[2].gsub("\`",'')

      # fdo.write(msql.join("\n"));fdo.write("\n")

      tablename.downcase!
      return nil if SKIP_TABLES.include?(tablename)
      puts "create table '#{tablename}'"
      msql.shift; msql.pop
      # puts "da #{msql.join("\n")}"
      attr=[]
      msql.each do |l|
        l.strip!
        l.downcase!
        next if !(/^unique key/ =~ l).nil?
        next if !(/^key/ =~ l).nil?
        l.sub! /,$/,''
        l.sub! /using btree/,''
        l.sub! /collate utf8_unicode_ci/,''
        l.sub! /longtext/,'text'
        l.sub! /mediumtext/,'text'
        l.gsub!("\`",'"')
        l.sub!('datetime','timestamp')
        l.sub!('tinyint(1)','smallint')
        l.sub!('tinyint(4)','integer')
        l.sub!('smallint(6)','integer')
        if !(/auto_increment/ =~ l).nil?
          attr << "#{l.split.first} SERIAL"
          next
        end
        if !(/default current_timestamp/ =~ l).nil?
          attr << "#{l.split.first} timestamp DEFAULT now()"
          next
        end
        if !(idx=/comment '/ =~ l).nil?
          l=l[0..idx-1]
        end

        l.sub!('int(11)','integer')
        attr << l
      end
      return [tablename,%Q{CREATE TABLE cipes."#{tablename}" (\n#{attr.join(",\n")}\n);}]
    end

    do_insert=lambda do |msql|
      # puts "do_insert: #{msql}"
      return nil if (i=/ VALUES$/=~msql).nil?
      # INSERT INTO `nome della tabella` VALUES
      tablename=msql[12..i-1].gsub("\`",'')
      tablename,fields=tablename.split(" (")
      return nil if SKIP_TABLES.include?(tablename)
      attrnames = "(#{fields}".downcase
      msql.slice!(0,i)
      msql.gsub!("\\'", "''")
      msql.gsub!('\"', '"')
      msql.gsub!('\n', '')
      return [tablename,%Q{INSERT INTO cipes."#{tablename}" #{attrnames} VALUES}]
    end

    fdr = File.new(srcfile, "r")
    cnt=0
    tabledef=[]
    insert_cnt=0

    fdo.write(setsqlvars)

    fdr.each_line do |line|
      cnt+=1
      if !(i=/^CREATE TABLE / =~ line).nil?
        insert_cnt=0
        tabledef << line.chomp
        next
      end
      if tabledef.size!=0
        tabledef << line.chomp
        if !(/^\) / =~ line).nil?
          tabname,sql=do_create_table.call(tabledef)
          tabledef=[]
          if !sql.nil?
            fdo.write(sql);fdo.write("\n")
          end
        end
      end
      if !(i=/^INSERT INTO / =~ line).nil?
        tabname,sql=do_insert.call(line.chomp)
        puts "insert per tabname #{tabname}"
        if !sql.nil?
          fdo.write(sql)
          fdo.write("\n")
          insert_cnt+=1
        end
      end
      if !(i=/^\(/ =~ line).nil?
        line.gsub!("'0000-00-00 00:00:00'","NULL")
        fdo.write(line)
      end
    end
    fdr.close
    fdo.close
  end
  converti_file(sourcefile,outfile)

end
