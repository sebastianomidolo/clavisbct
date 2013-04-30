class CreateAttachments < ActiveRecord::Migration
  def up

    create_table :attachment_categories, :id=>false do |t|
      t.string :code, :null=>false, :limit=>1
      t.string :label, :null=>false, :limit=>32
      t.string :description, :limit=>255
    end
    
    create_table :attachments, :id=>false do |t|
      t.integer :d_object_id, :null=>false
      t.integer :attachable_id, :null=>false
      t.integer :position
      t.string  :attachable_type, :limit=>24, :null=>false
      t.string  :attachment_category_id, :limit=>1
    end
    execute <<-SQL
      ALTER TABLE attachment_categories ADD PRIMARY KEY(code);
      ALTER TABLE attachments ADD PRIMARY KEY(attachable_type,attachable_id,d_object_id);

      ALTER TABLE attachments ADD CONSTRAINT attachment_category_id_fkey
        FOREIGN KEY(attachment_category_id) REFERENCES attachment_categories
         ON UPDATE CASCADE ON DELETE SET NULL;
      ALTER TABLE attachments ADD CONSTRAINT d_object_id_fkey
        FOREIGN KEY(d_object_id) REFERENCES d_objects
         ON UPDATE CASCADE ON DELETE CASCADE;
    SQL
  end
  def down
    drop_table :attachments
    drop_table :attachment_categories
  end
end
