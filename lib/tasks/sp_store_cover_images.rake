# -*- mode: ruby;-*-

desc 'Inserisce in oggetti digitali le immagini presenti nelle bibliografie fatte con SenzaParola'

task :sp_store_cover_images => :environment do
  f=DObjectsFolder.find(33115)
  user=User.find_by_email('seba')
  destpath=f.filename_with_path
  SpBibliography.all.each do |b|
    next if b.cover_image.nil?
    fname="#{b.title}_#{b.id}.jpg"
    destfile=File.join(destpath, fname)
    puts "#{b.id}: #{b.title} >> #{destfile}"
    FileUtils.cp(b.cover_image, destfile)
    o=DObject.trova_o_crea(f.id, fname, user)
    puts "nuovo o esistente oggetto: #{o.inspect}"
    break
  end
  puts f.digital_objects_mount_point
  puts "Ok files in #{destpath}"
  folder = destpath.sub(f.digital_objects_mount_point,'')
  # puts "eseguo scan su #{folder}"
  # numfiles=DObject.fs_scan(folder)
  # puts "numfiles: #{numfiles}"
end


