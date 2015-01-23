class ClavisConsistencyNote < ActiveRecord::Base
  self.table_name='clavis.consistency_note'
  self.primary_key = 'consistency_note_id'

  attr_accessible :collocazione_per

  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id

  has_many :clavis_items, :foreign_key=>:manifestation_id, :primary_key=>:manifestation_id


  def casse
    if self.collocazione_per.nil?
      sql="SELECT * FROM clavis.periodici_in_casse WHERE consistency_note_id=#{self.consistency_note_id} ORDER BY column_number"
    else
      sql="SELECT * FROM clavis.periodici_in_casse WHERE collocazione_per=#{self.collocazione_per} and (consistency_note_id is null or consistency_note_id=#{self.id}) ORDER BY column_number"
    end
    ClavisConsistencyNote.find_by_sql(sql)
  end

  def ClavisConsistencyNote.create_periodici_in_casse
    require 'csv'

    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("import",tempdir)
    tempfile=tf.path
    tempfile="/tmp/provaimport.sql"
    fd=File.open(tempfile,'w')
    sql=%Q{BEGIN; DROP TABLE clavis.periodici_in_casse; COMMIT;
       CREATE TABLE clavis.periodici_in_casse
       (consistency_note_id integer, column_number integer, collocazione_per integer, consistenza text,
          cassa varchar(20), annata text, note text);\n}
    fd.write(sql)

    doc_key="1q69AxbCy4i_mchKvAm_-3iiVUUrvY0Ks0VzQIgqEmjo"
    url="https://docs.google.com/spreadsheets/d/#{doc_key}/export?format=csv"

    # Url del foglio "Altre collocazioni"
    url2="https://docs.google.com/spreadsheets/d/#{doc_key}/export?format=csv&gid=1308599185"

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    doc1=response.body

    uri = URI.parse(url2)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    doc2=response.body


    fd.write("COPY clavis.periodici_in_casse(column_number,collocazione_per,consistenza,cassa,annata,note,consistency_note_id) FROM STDIN;\n")
    cnt=0
    CSV.parse(doc1.toutf8) do |row|
      cnt+=1
      next if cnt==1
      next if row.first.nil?
      row[5]="\\N" if row[5].blank?
      fd.write("#{cnt}\t#{row.join("\t")}\n")
    end
    fd.write("\\.\n")

    fd.write("COPY clavis.periodici_in_casse(column_number,consistency_note_id,cassa,annata,note) FROM STDIN;\n")
    cnt=0
    CSV.parse(doc2.toutf8) do |row|
      row.shift
      puts row.inspect
      cnt+=1
      next if cnt==1 or row.first.nil?
      fd.write("#{cnt}\t#{row.join("\t")}\n")
    end
    fd.write("\\.\n")
    fd.close

    config = Rails.configuration.database_configuration
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username} -f #{tempfile}"
    Kernel.system(cmd)
    tf.close(true)
  end


  def ClavisConsistencyNote.update_collocazione_per

    if !self.attribute_names.include?('collocazione_per')
      self.connection.execute("alter table #{self.table_name} add column collocazione_per integer")
    end
      
    sqlfile="/tmp/temp_consistenze.sql"
    fd=File.open(sqlfile, "w")
    fd.write("UPDATE clavis.consistency_note SET collocazione_per = NULL;\n")
    fd.write("CREATE TEMP TABLE aggiorna_consistenze (consistency_note_id integer, collocazione_per integer);\n")
    fd.write("COPY aggiorna_consistenze(consistency_note_id,collocazione_per) FROM STDIN;\n")
    sql=%Q{SELECT consistency_note_id,collocation FROM clavis.consistency_note WHERE library_id = 2 and collocation ~* 'per'}
    ActiveRecord::Base.connection.execute(sql).each do |r|
      sc=r['collocation'].downcase.gsub('. ','.')
      ar=sc.split('.')
      i=ar.index('per')
      next if i.nil?
      if r['collocation'] =~ /cd/i
        # puts "skip #{r['collocation']}"
        next
      end
      i+=1
      collocazione_per=ar[i].to_i

      ar.shift(i)
      if ar.size==3
        # puts "#{r['collocation']} i=#{i} => #{ar.size}"
        collocazione_per=9999
        # puts "#{r['collocation']} i=#{i} => #{collocazione_per}"

        # puts "#{r['consistency_note_id']} => #{r['collocation']} i=#{i} => #{collocazione_per}"
        # puts "UPDATE clavis.consistency_note SET collocazione_per=#{r['collocation']} #{collocazione_per} WHERE consistency_note_id=#{r['consistency_note_id']};"
      end
      fd.write("#{r['consistency_note_id']}\t#{collocazione_per}\n")
    end
    fd.write("\\.\n")
    fd.write(%Q{UPDATE clavis.consistency_note AS cn SET collocazione_per = ac.collocazione_per
      FROM aggiorna_consistenze ac WHERE ac.consistency_note_id=cn.consistency_note_id;
      DROP TABLE aggiorna_consistenze;
      });
    fd.close

    config   = Rails.configuration.database_configuration
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username} -f #{sqlfile}"
    Kernel.system(cmd)
    sqlfile="/home/ror/clavisbct/public/aggiusta_consistenze.sql"
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username} -f #{sqlfile}"
    # Kernel.system(cmd)
  end
end
