# RAILS_ENV=development rake db:migrate VERSION=20130225132931; RAILS_ENV=development rake db:migrate
# RAILS_ENV=production rake db:migrate VERSION=20130225132931; RAILS_ENV=production rake db:migrate

class CreateSubjects < ActiveRecord::Migration
  def up
    create_table :subjects do |t|
      t.text :heading, :null=>false
    end
    create_table :subject_subject, :id=>false do |t|
      t.integer :s1_id, :null=>false
      t.integer :s2_id, :null=>false
      t.string :linktype, :null=>false, :limit=>24
    end
    execute <<-SQL
          ALTER TABLE public.subject_subject add primary key(linktype,s1_id,s2_id);
          CREATE INDEX subjects_heading_idx on public.subjects(heading);
    SQL
  end
  
  def down
    drop_table :subject_subject
    drop_table :subjects
  end

end
