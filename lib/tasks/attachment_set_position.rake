# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake attachment_set_position
# In production:
# RAILS_ENV=production  rake attachment_set_position

desc 'Attachments set position from filenames'

task :attachment_set_position => :environment do
  sql=%Q{select attachable_type,attachable_id,count(*) from attachments where position isnull group by attachable_type,attachable_id having count(*)>1;}
  ActiveRecord::Base.connection.execute(sql).each do |r|
    Attachment.set_position(r['attachable_id'])
  end

end


