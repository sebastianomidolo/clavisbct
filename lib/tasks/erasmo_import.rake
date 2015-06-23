# -*- mode: ruby;-*-

desc 'Importazione dati unimarc da Erasmo'

task :erasmo_import => :environment do
  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]


  def elimina_newline(fname)
    marcfile=fname.sub(/.txt$/,'.marc')
    return if File.exists?(marcfile)
    cmd = "tr --delete '\r\n' < #{fname} > #{marcfile}"
    Kernel.system(cmd)
  end

  def estrai_7xx(record)
    h=Hash.new
    record.tags.each do |tag|
      record.fields(tag).each do |datafield|
        next if (tag =~ /^7/).nil?
        h[tag] = [] if h[tag].nil?
        h[tag] << datafield.to_marchash
        puts "#{tag} => #{datafield.inspect}"
      end
    end
  end

  def elabora_marcfile(marcfile)
    puts "elaborazione #{marcfile}"
    reader = MARC::Reader.new(marcfile, :external_encoding => "UTF-8")
    cnt=0
    res = ''
    for record in reader
      cnt+=1
      puts cnt
      estrai_7xx(record)
      next
      
      h=Hash.new
      # record.leader
      h[:leader]=record.leader
      res << %Q{<l>#{record.leader}</l><c001>#{record.fields('001').first.value}</c001>}
      record.tags.sort.each do |tag|
        record.fields(tag).each do |datafield|
          # h[tag] = [] if h[tag].nil?
          # h[tag] << datafield.to_marchash
          # puts "#{tag} => #{datafield.inspect}"
        end
      end
      res << "</r>\n"
    end
    puts res
  end

  source_dir="/home/seb/centro_documentazione_pedagogica/unimarc"
  entries=Dir.entries(source_dir).delete_if {|z| ['.','..'].include?(z)}.sort
  entries.each do |entry|
    next if File.extname(entry)!=".txt"
    fname=File.join(source_dir,entry)
    elimina_newline(fname)
  end

  entries.each do |entry|
    next if File.extname(entry)!=".marc"
    elabora_marcfile(File.join(source_dir,entry))
  end

end
