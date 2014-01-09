# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake find_d_objects
# In production:
# RAILS_ENV=production  rake find_d_objects

desc 'Metadata import from filesystem'

task :find_d_objects => :environment do

  tempdir = File.join(Rails.root.to_s, 'tmp')
  tf = Tempfile.new("import",tempdir)
  tempfile=tf.path
  puts tempfile
  fdout=File.open(tempfile,'w')

  fdout.write(%Q{ALTER TABLE public.attachments DROP CONSTRAINT "d_object_id_fkey";
-- TRUNCATE public.d_objects;
-- SELECT setval('public.d_objects_id_seq', 1);\n})

  numfiles=0
  dirs=[
        'bct',
        'libroparlato',
        'procultura/archives',
        'seshat/archives',
        'mp3clips',
       ]
  # Limito l'esecuzione alla dir del libro parlato:
  dirs=[
        'libroparlato',
       ]

  dirs.each do |folder|
    fdout.write(%Q{DELETE FROM public.d_objects WHERE filename LIKE '#{folder}/%';
SELECT setval('public.d_objects_id_seq', (select max(id) FROM public.d_objects)+1);
COPY public.d_objects (filename, bfilesize, f_ctime, f_mtime, f_atime, mime_type) FROM stdin;\n})
    numfiles+=DObject.fs_scan(folder, fdout)
    fdout.write("\\.\n")
  end
  # See /extras/sql/attachments_insert.sql (ADD CONSTRAINT "d_object_id_fkey")
  fdout.close

  cmd="/bin/cp #{tempfile} /tmp/d_objects_testfile.sql"
  puts cmd
  Kernel.system(cmd)

  #config = Rails.configuration.database_configuration
  #dbname=config[Rails.env]["database"]
  #username=config[Rails.env]["username"]
  #cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{tempfile}"
  # puts cmd
  # Kernel.system(cmd)

  tf.close(true)
  puts "importazione oggetti digitali => totale files analizzati #{numfiles}"
end


