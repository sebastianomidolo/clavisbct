# -*- mode: ruby;-*-

desc 'Reimportazione topografico civica da files xls'
# Nota: solo per quello che non si trovano ancora in ClavisBCT

# Ispirato a litrinlinea_orig/lib/tasks/topografico_civica.rake

xlsdir='/home/storage/nowww/topografico civica'

require 'roo'


task :reimporta_topografico_civica_da_xls => :environment do
  lavora(xlsdir)
end


def lavora(sourcedir)
  outfile="/tmp/collocazioni_da_inserire.txt"
  fdout=File.open(outfile,'w')
  puts "da #{sourcedir}"
  cnt=0
  # Dir.glob(File.join(sourcedir, '409.xls')).each do |file|
  Dir.glob(File.join(sourcedir, '*.xls')).each do |file|
    cnt+=1
    shelf=shelfname(file)
    next if shelf.nil?
    puts "#{cnt} - #{file} (shelf: #{shelf})"
    begin
      read_excel_file(Roo::Excel.new(file), shelf, fdout)
    rescue
      puts "Errore: #{$!}"
    end
  end
  fdout.close
end


def shelfname(fname)
  n=File.basename(fname)
  x=n.split('.')
  x.pop
  x=x.join('.')
  i=x.to_i
  shelf=nil
  if i==0
    if !(/(\d.*)/ =~ x).nil?
      shelf=$1
    else
      puts "non determinato - #{x}"
      nil
    end
  else
    shelf=i
  end
  return shelf
end


def read_excel_file(excel,shelf,fd)
  excel.sheets.each do |s|
    excel.default_sheet=s
    puts "---> #{shelf} lettera #{s} (last_row: #{excel.last_row})"
    next if excel.last_row.nil?
    collocazione=''
    2.upto(excel.last_row) do |line|
      # puts "line: #{line}"
      titolo   = excel.cell(line,'C')
      catena   = excel.cell(line,'A').to_i
      # return if catena==0
      if titolo.blank? or catena.blank? or catena==0
        # puts "attenzione: salto #{s} (catena: #{catena}) #{excel.row(line)}"
        next
      end
      autore   = excel.cell(line,'B')
      if !autore.nil?
        autore = autore.strip
        autore = autore.split("\n").join(" ")
        autore.squeeze!(' ')
      end
      luogo    = excel.cell(line,'D')
      inventario = excel.cell(line,'F')
      if !inventario.nil?
        inventario = inventario.to_i
      else
        inventario='\\N'
      end
      anno     = excel.cell(line,'E')
      anno = anno.to_i
      anno = nil if anno==0
      ingresso = excel.cell(line,'F').to_i
      note_interne = excel.cell(line,'G')
      collocazione="#{shelf}.#{s}.#{catena}"
      titolo.gsub!("\n", ' ')
      if autore.blank?
        bibdescr = titolo.strip
      else
        bibdescr = "#{autore}. #{titolo.strip}"
      end
      bibdescr << ". - #{luogo}" if !luogo.blank?
      bibdescr << ", #{anno}" if !anno.nil?
      serieinv='V'
      fd.write "#{collocazione}\t#{bibdescr}\t#{serieinv}\t#{inventario}\tRecuperato da topografico excel\n"
      # puts "collocazione: #{collocazione} (#{titolo})"
    end
  end
end
