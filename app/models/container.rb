class Container < ActiveRecord::Base
  attr_accessible :item_title

  has_many :container_items, foreign_key: :label, primary_key: :label, order: 'row_number',
  include: [:clavis_item,:clavis_manifestation]
  belongs_to :clavis_library, foreign_key: :library_id, primary_key: :library_id

  def Container.sqlcopy_from_gd(key,fd,gd_session,library_id=2)
    puts key
    s=gd_session.spreadsheet_by_key(key)
    ws=s.worksheets.first
    rows=Array.new(ws.rows)
    rows.shift
    cnt=1
    rows.each do |row|
      cnt+=1
      a=[]
      [0,3,4,5,6].each do |i|
        a << (row[i].blank? ? '\\N' : row[i])
      end
      a << library_id
      a << key
      fd.write("#{cnt}\t#{a.join("\t")}\n")
    end
    rows
  end

  def Container.barcodes
    sql="select distinct barcode from container_items cni join clavis.item ci using(item_id) where barcode notnull and opac_visible='1'"
    # sql="select distinct barcode from container_items cni join clavis.item ci using(item_id) where barcode notnull"
    ActiveRecord::Base.connection.execute(sql).to_a
  end

  def Container.svuota_e_riempi
    require 'csv'

    config = Rails.configuration.database_configuration
    user_ids = config[Rails.env]["container_users"]
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]

    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("import",tempdir)
    tempfile=tf.path
    tempfile="/tmp/container_import.sql"
    fd=File.open(tempfile,'w')
    sql=%Q{-- TRUNCATE #{Container.table_name};
TRUNCATE #{ContainerItem.table_name};
SELECT setval('containers_id_seq', (select max(id) FROM containers)+1);
-- SELECT setval('containers_id_seq', 1);
SELECT setval('container_items_id_seq', 1);
COPY #{ContainerItem.table_name} (row_number,label,item_title,manifestation_id,item_id,
       consistency_note_id,library_id,google_doc_key) FROM STDIN;
    }
    fd.write(sql)
    puts "ok #{Time.now}"
    gd_session=User.googledrive_session
    User.find(user_ids).each do |user|
      Container.sqlcopy_from_gd(user.google_doc_key,fd,gd_session)
    end
    fd.write("\\.\n")
    fd.write("INSERT INTO containers (label,library_id) (SELECT DISTINCT ci.label,2 FROM container_items ci LEFT JOIN containers c USING(label) WHERE c.label IS NULL);\n")
    fd.close

    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username} -f #{tempfile}"
    Kernel.system(cmd)
    tf.close(true)
  end

end
