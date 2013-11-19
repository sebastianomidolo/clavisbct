# -*- mode: ruby;-*-


desc 'Aggiorna log file accessi dng su google drive (sperimentale - 14 novembre 2013)'

task :googledrive_log => :environment do
  file='/tmp/last_session_id'
  if !File.exists?(file)
    DngSession.last.log_session_id
  else
    last_session_id=File.read(file).to_i
    puts "last_session_id: #{last_session_id}"
    if last_session_id!=-1
      puts "#{Time.now} aggiorno google_drive fino alla sessione #{last_session_id}..."
      fd=File.open(file, 'w')
      fd.write('-1')
      fd.close
      DngSession.google_drive_log
    end
  end
end
