# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake senza_parola
# In production:
# RAILS_ENV=production  rake senza_parola

desc 'Importazione bibliografie da SenzaParola'

task :senza_parola => :environment do

  def leggi_info_bibliografia(sourcedir)
    res={}
    i=Tcl::Interp.load_from_file(File.join(sourcedir, 'info.tcl'))
    # puts File.join(sourcedir, 'info.tcl')
    i.eval("array name ProInfo").split.each do |vn|
      v=i.var("ProInfo(#{vn})").value
      next if v.blank?
      if ['ctime','mtime'].include?(vn)
        res[vn.to_sym] = Time.parse(i.eval(%Q{clock format #{v} -format "%Y-%m-%d %H:%M:%S"}))
      else
        res[vn.to_sym] = v.strip
      end
    end
    res
  end

  def importa_senza_parola(source, dbname, username)
    # Primo livello: elenco delle bibliografie - destinazione => sp_bibliography
    # Campi da importare: comm, ctime, mtime, name, nascondi, nsked, p_status, subname
    rootdir=File.join(source, 'Projects')
    fields={
      :comm => :comment,
      :ctime => :created_at,
    }
    Dir.glob(File.join(rootdir, '*')).each do |d|
      infobib = leggi_info_bibliografia(d)
      puts infobib.inspect
    end
    
  end

  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  source=config[Rails.env]["sp_source"]
  importa_senza_parola(source, dbname, username)

end

