class ClavisAttachment < ActiveRecord::Base
  self.table_name = 'clavis.attachment'

  # Uso: ClavisAttachment.download_manifestations_attachments(DObjectsFolder.find(33317));nil
  def ClavisAttachment.download_manifestations_attachments(destfolder)
    sql = "select attachment_id,object_id as manifestation_id from clavis.attachment where object_type='Manifestation' and attachment_type!='E'"
    self.connection.execute(sql).to_a.each do |r|
      uri = "https://sbct.comperio.it/index.php?file=#{r['attachment_id']}"
      fname = r['attachment_id']
      obj=DObject.new(d_objects_folder_id:destfolder.id, name:fname, access_right_id:0)
      obj.x_mid=r['manifestation_id'].to_s
      next if File.exists?(obj.filename_with_path)
      puts "uri: #{uri}"
      res = Net::HTTP.get_response(URI(uri))
      if res.class==Net::HTTPOK
        fd=File.open(obj.filename_with_path,'wb')
        fd.write(res.body)
        fd.close
        obj.save
      else
        puts "errore scaricamento #{uri} - #{res.class}"
      end
    end
  end

  def ClavisAttachment.categories_sql
    sql=%Q{select a.object_type,a.attachment_type,lv.value_label,count(*) from
    clavis.attachment a join clavis.lookup_value lv on
    (lv.value_key=a.attachment_type) where lv.value_language='it_IT'
       and lv.value_class='ATTACHTYPE'
      group by a.object_type,a.attachment_type,lv.value_label order by object_type,attachment_type;}
    puts sql
  end

end
