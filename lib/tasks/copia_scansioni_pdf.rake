# -*- mode: ruby;-*-

desc 'Copia scansioni PDF lettere autografe'


def copia_scansioni_mainloop(basedir, destdir)
  entries=Dir.entries(basedir).delete_if {|z| ['.','..'].include?(z)}.sort
  entries.each do |entry|
    file_or_dir=File.join(basedir,entry)
    if File.directory?(file_or_dir)
      # puts "questa e' una directory: #{file_or_dir}"
      mainloop(file_or_dir, destdir)
    else
      sourcefile=file_or_dir
      fname=File.basename(entry).downcase
      id,ext=fname.split('.')
      # puts "lettera con id #{id}"
      destfile=File.join(destdir, "#{id}.pdf") 
      if File.exists?(destfile)
        msg=''
      else
        msg=' [nuovo]'
        FileUtils.cp sourcefile, destfile
        l=BctLetter.find(id)
        l.pdf=true
        l.save if l.changed?
      end
      puts "http://clavisbct.comperio.it/bct_letters/#{id}#{msg}"
    end
  end
end



task :copia_scansioni_pdf => :environment do
  config = Rails.configuration.database_configuration
  destdir=config[Rails.env]["lettereautografe_basedir"]

  sourcedir="/home/seb/BCT/wca22014/linux64/UffManoscritti/scansioni/lettereautografe"
  copia_scansioni_mainloop sourcedir, destdir
end

