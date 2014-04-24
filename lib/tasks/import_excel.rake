# -*- mode: ruby;-*-

desc 'Import generico da fogli excel'

def analizza_foglio(excel, sheet_number, sheet_name, excel_file)
  if excel.sheet(sheet_number).last_column.blank?
    puts "Il foglio numero #{sheet_number} di #{excel_file.file_name} non sembra contenere dati"
    return
  end
  if sheet_name.blank?
    puts "Errore?..."
  end
  puts "#{excel.class} - sheet_number #{sheet_number}, sheet_name==#{sheet_name}"
  es=ExcelSheet.find_or_create_by_sheet_number_and_excel_file_id(sheet_number,excel_file.id)
  es.sheet_name=sheet_name
  es.save
  es.sql_createtable(excel)
  es.reload
  begin
    es.import_from_sourcefile(excel)
  rescue
    puts "errore da import_from_sourcefile per ExcelSheet #{es.id}: #{$!}"
  else
    puts "importati #{es.sql_count} records da #{excel_file.file_name}"
  end
  es.postload_sql_exec
  es.alter_data_types
  return es
end

def analizza_excel(excel, ef)
  cfg=ef.load_config
  sheets = cfg[:sheets].nil? ? excel.sheets : cfg[:sheets]
  cnt=0
  puts "=> #{ef.file_name} updated_at #{ef.updated_at}"
  sheets.each do |s|
    puts "  => #{s}"
    begin
      analizza_foglio(excel, cnt, s, ef)
    rescue
      puts "Errore: #{$!} - continuo..."
    end
    cnt+=1
  end
end

def imposta_excel_file(filename)
  return nil if (f=ExcelFile.find_or_create_by_file_name(filename)).nil?
  f.file_size=File.size(filename)
  f.updated_at=File.mtime(filename)
  f.save
  f
end

def mainloop(basedir,fdout)
  post_sql_files=[]
  entries=Dir.entries(basedir).delete_if {|z| ['.','..'].include?(z)}.sort
  entries.each do |entry|
    # puts entry
    file_or_dir=File.join(basedir,entry)
    if File.directory?(file_or_dir)
      # puts "questa e' una directory: #{file_or_dir}"
      mainloop(file_or_dir,fdout)
    else
      next if File.extname(entry)!=".xls"
      fname=File.join(basedir,entry)
      next if (excel_file=imposta_excel_file(fname)).nil?
      # next if fname!="/home/seb/xls/celdes/celdes_musicale_admin_report_ordini.xls"
      # next if fname!="/home/seb/xls/celdes/ordini_periodici_musicale.xls"
      # next if fname!='/home/seb/xls/varie/CatalogoLibroParlato.xls'
      begin
        excel=Roo::Excel.new(fname)
        analizza_excel(excel, excel_file)
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
     DROP SCHEMA excel_files_tables CASCADE;
     CREATE SCHEMA excel_files_tables;
  })
  mainloop('/home/seb/xls',fdout)
  fdout.close
  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  # cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{sqlfile}"
  # puts cmd
  # Kernel.system(cmd)
  puts "finito"
end
