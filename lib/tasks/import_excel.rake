# -*- mode: ruby;-*-

desc 'Import generico da fogli excel'

def analizza_foglio(sheet_number,foglio,s,excel_file,fdout)
  puts "analizza_foglio numero #{sheet_number}, #{foglio}: #{s.last_column} colonne; #{s.last_row} righe"
  es=ExcelSheet.find_or_create_by_sheet_number_and_excel_file_id(sheet_number,excel_file.id)
  es.sheet_name=foglio
  es.save if es.changed?
  # col_index={};i=0;('A'..'ZZ').each {|x| i+=1;col_index[i]=x}
  col_index={};i=0;('A'..'ZZ').each {|x| i+=1;col_index[i]=format("%2s",x)}
  col_index={};i=0;('A'..'ZZ').each {|x| i+=1;col_index[i]=format("%2s",x).sub(' ','_')}

  puts "first row: #{s.first_row} - last row: #{s.last_row}"
  # (s.first_row..s.last_row).each do |cn|
  (1..s.last_row).each do |cn|
    next if cn>s.last_column
    # puts "colonna #{cn} #{foglio}/#{col_index[cn]}; s.column(cn): #{s.column(cn).size}"
    i=s.first_row-1
    s.column(cn).each do |t|
      i+=1
      next if t.blank?
      if t.class==Float
        intero=t.to_i
        t = intero!=0 ? intero : t.to_s
      else
        t=t.to_s.strip
        t.gsub!("\r\n",'\r')
        # t.gsub!("\t",' ')
      end
      # puts "cella #{i} => #{foglio} #{t.class} #{col_index[cn]}/#{i} => #{t}"
      fdout.write(%Q{#{es.id}\t#{i}\t#{col_index[cn]}\t#{t}\n})
    end
    # puts "Uscito da loop interno"
  end
  # puts "uscito"
end

def analizza_excel(e, excel_file, fdout)
  fdout.write(%Q{COPY public.excel_cells (excel_sheet_id,cell_row,cell_column,cell_content) FROM stdin;\n})
  cnt=0
  e.sheets.each do |s|
    analizza_foglio(cnt,s,e.sheet(s), excel_file,fdout)
    cnt+=1
  end
  fdout.write("\\.\n")
end

def imposta_excel_file(filename)
  return nil if (f=ExcelFile.find_or_create_by_file_name(filename)).nil?
  f
end

def mainloop(basedir,fdout)
  post_sql_files=[]
  entries=Dir.entries(basedir).delete_if {|z| ['.','..'].include?(z)}.sort
  entries.each do |entry|
    puts entry
    file_or_dir=File.join(basedir,entry)
    if File.directory?(file_or_dir)
      puts "questa e' una directory: #{file_or_dir}"
      mainloop(file_or_dir,fdout)
    else
      next if File.extname(entry)!=".xls"
      puts entry
      fname=File.join(basedir,entry)
      next if (excel_file=imposta_excel_file(fname)).nil?
      puts "foglio: #{excel_file.inspect}"
      puts "entry #{entry}"
      puts "fname: #{fname}"
      begin
        e=Roo::Excel.new(fname)
        analizza_excel(e, excel_file,fdout)
        sqlfile=fname.sub(/.xls$/,'.sql')
        if File.exists?(sqlfile)
          post_sql_files << sqlfile
        end
      rescue
        puts "Errore: #{$!}"
        exit
      end
    end
  end
  post_sql_files.each do |f|
    fdout.write("-- INIZIO sql da #{f}\n")
    fdout.write(File.read(f))
    fdout.write("-- FINE sql da #{f}\n")
  end
end

task :import_excel => :environment do
  sqlfile="/tmp/import_excel.sql"
  fdout=File.open(sqlfile,"w")
  ExcelFile.connection.execute(%Q{
          TRUNCATE public.excel_files CASCADE;
          SELECT setval('public.excel_files_id_seq', 1);
          SELECT setval('public.excel_sheets_id_seq', 1);
          SELECT setval('public.excel_cells_id_seq', 1);
  })
  mainloop('/home/seb/xls',fdout)
  fdout.close
  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{sqlfile}"
  Kernel.system(cmd)
end
