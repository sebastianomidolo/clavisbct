# coding: utf-8
# -*- mode: ruby;-*-

desc 'Importazione nuovi libri parlati'

task :aggiorna_libroparlato => :environment do
  config = Rails.configuration.database_configuration
  esamina_cartella_di_provenienza(config[Rails.env]["libroparlato_upload"], "/home/storage/preesistente/libroparlato")
end

def errore(msg)
  puts "msg: #{msg}"
end

def esamina_cartella_di_provenienza(sourcedir,destdir)
  puts "esamino #{sourcedir}"
  Dir.glob("/home/seb/BCT/wca22014/linux64/LP2mog/upload_libroparlato/*").each do |dirname|
    slot=File.basename(dirname)
    puts "in slot #{slot}"

    Dir.glob("#{dirname}/*").each do |folder|
      newfolder=File.basename(folder)
      target=File.join(destdir,slot)
      collocazione=TalkingBook.filename2colloc(newfolder)
      t_book=TalkingBook.where("n = replace('#{collocazione}','CD ','')").first
      if t_book.nil?
        errore "Record non trovato nel catalogo libro parlato per la collocazione #{collocazione}"
        next
      else
        if t_book.manifestation_id.nil?
          errore "manifestation_id non trovata (#{collocazione}) per https://clavisbct.comperio.it/talking_books/#{t_book.id}"
          next
        end
      end
      puts "chiamo book_update su TalkingBook numero #{t_book.id} - collocazione #{collocazione}"
      source_folder=File.join(slot,File.basename(folder))
      t_book.book_update(source_folder)
    end
  end
end
