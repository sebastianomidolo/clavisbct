# -*- coding: utf-8 -*-
# -*- mode: ruby;-*-

desc 'Importazione schede bibcircs in bioiconografico'

task :bct_cards_import => :environment do
  ARGV.each { |a| task a.to_sym do ; end }
  sourcedir = ARGV[1]
  letters = ARGV[2]
  pattern = '_501-550_0027.'
  puts "sourcedir: '#{sourcedir}'\nassociazione lettere: '#{letters}'"

  ref = Hash.new
  File.read(letters).each_line do |l|
    letter,numbers = l.split(' ')
    n_from,n_to = numbers.split('-').map(&:to_i)
    ref[letter]=[n_from,n_to]
  end

  # Il presupposto è che il nome del file contenga tra numero, esempio:
  # "ROMANZI_RACCONTI_601-650_0030.jpg"
  # dove i primi due numeri rappresentano il range (da - a) del "lotto di schede"
  # mentre il l'ultimo numero è il progressivo all'interno del "lotto"
  # NB Questo è il formato che mi è stato dato in input
  cnt = 0
  Dir.glob("#{sourcedir}/*").sort.each do |fname|
    fn=File.basename(fname)
    # puts "fn: #{fn}"
    from,to,number = fn.scan(/\d+/).map(&:to_i)
    next if number.nil? or number==51
    abs_number = from + number - 1
    
    ref.each_pair do |lettera,v|
      if abs_number.between?(v[0],v[1])
        # puts "from #{from} - to #{to} - number #{number} (numero assoluto: #{abs_number})"
        puts "fn: #{fn} LETTERA #{lettera} NUMERO #{abs_number}"
        cnt += 1
        b=BioIconograficoCard.new
        b.d_objects_folder_id=33214
        b.name=fn
        b.tags={l:lettera,n:abs_number,ns:'bibcircs',user:'9',intestazione:''}.to_xml(root:'r',:skip_instruct => true, :indent => 0)
        b.save
        break
      end
    end
  end
  puts "fine lavoro, #{cnt} schede inserite"

end
