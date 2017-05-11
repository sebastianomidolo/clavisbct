# coding: utf-8
# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake doc_delivery_sync
# In production:
# RAILS_ENV=production  rake doc_delivery_sync

desc 'Sincronizza folder doc_delivery'

task :doc_delivery_sync => :environment do
  puts "doc_delivery_sync non è più utilizzato"
  exit
  def exec_sqlfile(sqlfile)
    config   = Rails.configuration.database_configuration
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username} -f #{sqlfile}"
    puts cmd
    Kernel.system(cmd)
  end

  sql=%Q{DELETE FROM public.d_objects WHERE filename LIKE 'doc_delivery/%';
SELECT setval('public.d_objects_id_seq', (select max(id) FROM public.d_objects)+1)}
  ActiveRecord::Base::connection.execute(sql)

  sqlfile="/tmp/doc_delivery_sync_step1.sql"
  fdout=File.open(sqlfile,'w')
  last=DObject.last
  fdout.write(%Q{COPY public.d_objects (filename, bfilesize, f_ctime, f_mtime, f_atime, mime_type) FROM stdin;\n})
  DObject.fs_scan('doc_delivery', fdout)
  fdout.write("\\.\n")
  lastid=last.id
  fdout.write("-- max id: #{lastid}\n")
  fdout.close
  exec_sqlfile(sqlfile)

  sqlfile="/tmp/doc_delivery_sync_step2.sql"
  fdout=File.open(sqlfile,'w')
  fdout.write(%Q{COPY public.attachments (d_object_id,attachable_id,"position",attachable_type,attachment_category_id,folder) FROM stdin;\n})
  pos=0
  precmid=precfolder=nil

  category='C'; # Da modificare in futuro
  DObject.find_by_sql("select * from public.d_objects where id>#{lastid} and filename like 'doc_delivery/%' order by lower(filename)").each do |o|
    o.write_tags_from_filename
    mid=o.xmltag(:mid)
    mid.strip! if !mid.nil?
    if !(/\A[-+]?\d+\z/ === mid)
      mid=nil
    end
    if o.parent_folder_with_metadata?
      folder = "\\N"
    else
      folder=o.parent_folder
    end
    # next if !o.xmltag(:uid).blank? or mid.blank?
    next if mid.blank?
    if folder!=precfolder
      pos=0
      precfolder=folder
    end
    if mid!=precmid
      pos=0
      precmid=mid
    end
    pos+=1
    fdout.write("#{o.id}\t#{mid}\t#{pos}\tClavisManifestation\t#{category}\t#{folder}\n")
  end
  fdout.write("\\.\n")
  fdout.close
  exec_sqlfile(sqlfile)
end
