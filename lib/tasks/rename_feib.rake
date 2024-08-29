# coding: utf-8
# -*- mode: ruby;-*-

desc 'Script specifico feib 2023 - lanciato una sola volta il 9 gennaio 2024'


def trova_prefisso(nome)
  # puts "trovo il prefisso per il file #{nome}"
  h = {
    amoretti: 'AMORETTI',
    archivio: 'ARCHIVIO',
    atria: 'ATRIA',
    bibliobus: 'BIBLIOBUS',
    bonhoeffer:  'BONHOEFFER|BONHOEFFR|BONOEFFER|BONHOFFER',
    calvino: 'CALVINO',
    carluccio: 'CARLUCCIO|CARCLUCCIO|CARKUCCIO',
    cartiera: 'CARTIERA',
    centrale:  'CENTRALE',
    centro: 'CENTRO INT',
    cognasso: 'COGNASSO',
    geisser:  'GEISSER|GEISSE',
    ginzburg: 'GINZBURG',
    levi: 'LEVI',
    marchesa: 'MARCHESA',
    mausoleo: 'MAUSOLEO|ROSIN',
    milani:  'MILANI',
    musicale:  'MUSICALE',
    passerin: 'PASSERIN',
    pavese: 'PAVESE',
    serra: 'SERRA',
    utoya: 'UTOYA',
  }
  retval = nil
  h.each_pair do |k,v|
    # puts "Confronto con #{v}"
    v.split('|').each do |x|
      rg=Regexp.new(x,'i')
      if nome =~ rg
        retval = k
        break
      end
    end
  end
  if retval.nil?
    # puts "non trovo bib per #{nome}"
  end
  return retval
end

def analyze_dir(name)
  supplier = File.basename(name)
  Dir[(File.join(name,'*'))].each do |file|
    fname=File.basename(file)
    # puts "vedo in #{name}"
    prefix = trova_prefisso(fname)
    if prefix.nil?
      puts "manca bib in #{name} ==> #{fname}"
    else
      destname = "#{prefix}_#{supplier}_#{fname}"
      destname.gsub!(' ', '_')
      target = File.join('/tmp/prova', destname)
      puts "nuovo nome: #{target}"
      FileUtils.cp(file, target)
    end
  end
end

task :rename_feib => :environment do
  #puts "non eseguo perché l'ho già fatto il 9 gennaio 2024 - operazione da eseguire una sola volta!"
  #exit

  wdir="/home/seb/feib/feib2023"
  Dir[(File.join(wdir,'*'))].each do |entry|
    analyze_dir(entry)
  end

end
