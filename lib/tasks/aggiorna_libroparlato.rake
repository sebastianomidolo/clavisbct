# coding: utf-8
# -*- mode: ruby;-*-

desc 'Importazione nuovi libri parlati'

task :aggiorna_libroparlato => :environment do
  config = Rails.configuration.database_configuration
  esamina_cartella_di_provenienza(config[Rails.env]["libroparlato_upload"], "/home/storage/preesistente/libroparlato")
end

def logmessage(msg)
  fn=TalkingBook.logfilename
  fdout=File.open(fn, 'a')
  fdout.write("#{msg}\n")
  puts "msg: #{msg}"
  fdout.close
end

def esamina_cartella_di_provenienza(sourcedir,destdir)
  fn=TalkingBook.logfilename
  fdout=File.open(fn, 'w')
  fdout.write("#{Time.now}: INIZIO ESECUZIONE script 'aggiorna_libroparlato.rake'\n\n")
  fdout.close
  logmessage "esamino #{sourcedir}"

  Dir.glob("#{sourcedir}/*").each do |dirname|
    slot=File.basename(dirname)
    logmessage "Entro in #{slot}"

    Dir.glob("#{dirname}/*").each do |folder|
      newfolder=File.basename(folder)
      target=File.join(destdir,slot)
      collocazione=TalkingBook.filename2colloc(newfolder)
      t_book=TalkingBook.where("n = replace('#{collocazione}','CD ','')").first
      if t_book.nil?
        logmessage "Record non trovato nel catalogo libro parlato per la collocazione #{collocazione}"
        next
      else
        if t_book.manifestation_id.nil?
          logmessage "manifestation_id non trovata (#{collocazione}) per https://clavisbct.comperio.it/talking_books/#{t_book.id}"
          next
        end
      end
      logmessage %Q{produco audio.zip per <a href="https://clavisbct.comperio.it/talking_books/#{t_book.id}/edit">#{t_book.titolo}</a> - collocazione #{collocazione}}
      begin
        source_folder=File.join(slot,File.basename(folder))
        t_book.book_update(source_folder)
      rescue
        logmessage "errore dopo t_book.book_update(#{source_folder}: #{$!}"
      end
    end
  end

  fn=TalkingBook.logfilename
  fdout=File.open(fn, 'a')
  fdout.write("\n#{Time.now}: FINE ESECUZIONE script 'aggiorna_libroparlato'\n")
  fdout.close
end
