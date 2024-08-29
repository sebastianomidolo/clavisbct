# coding: utf-8
# -*- mode: ruby;-*-

desc 'Script specifico per rinominare files che iniziano con numeri romani'
# https://archive.org/details/CEL-1-2739

# thanks to https://stackoverflow.com/questions/53033844/roman-to-integer-refactored
ROMAN_TO_INT =
  {
    i: 1,
    v: 5,
    x: 10,
    l: 50,
    c: 100,
    d: 500,
    m: 1000
  }

def roman_to_int(roman)
  numbers = roman.downcase.chars.map { |char| ROMAN_TO_INT[char.to_sym] }.reverse
  return nil if numbers.compact.size == 0
  numbers.inject([0, 1]) do |result_number, int|
    result, number = result_number
    int >= number ? [result + int, int] : [result - int, number]
  end.first
end

# Per rifare tutto da capo:
# cd /home/storage/preesistente/misc/IA/CEL-1-2739
# unzip /home/storage/preesistente/CoBiS/IA-CEL-1-2739/CEL-1-2739_images.zip  > /dev/null
# (sul db): delete from d_objects where d_objects_folder_id in(); (verificare gli id dei folder il cui contenuto va rimosso)
# time rake d_objects_scan misc/IA/CEL-1-2739
task :rename_roman_files => :environment do
  #puts "non eseguo perché l'ho già fatto il 20 luglio 2023 - operazione da eseguire una sola volta!"
  #exit
  wdir="/home/storage/preesistente/misc/IA/CEL-1-2739"
  cnt = 0
  Dir.glob("#{wdir}/*.jpg").sort.each do |f|
    cnt +=1
    fname=File.basename(f)
    fa = fname.split('_')
    rom = fa.first
    intero = roman_to_int(rom)
    if intero.nil?
      # puts "#{cnt}: (#{rom} non è un numero romano) #{fname}"
      # ...quindi il file è già stato rinominato da romano a arabo
      # mi resta da rinominare il progressivo finale
      i = fname.index('.jpg') - 1
      dest_fname = fname[0..i]
      progr = sprintf('%.04d',cnt)
      bn = dest_fname.split('_')
      bn.pop
      dest_fname = "#{File.join(wdir, bn.join('_'))}_#{progr}.jpeg"
      puts "#{cnt}: #{f} => #{dest_fname}"
      # File.rename(f,dest_fname)
      next
    end
    intero = sprintf('%02d',intero)
    folder = File.join(wdir,intero)
    FileUtils.mkdir_p(folder)
    # dest_fname = File.join(wdir, "#{intero}_#{fname}")
    # puts "#{cnt}: (#{rom} => #{intero}) #{f} => #{folder}"
    FileUtils.mv(f,folder)
  end
  puts "totale #{cnt}"

end
