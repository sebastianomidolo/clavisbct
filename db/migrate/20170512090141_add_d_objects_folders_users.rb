class AddDObjectsFoldersUsers < ActiveRecord::Migration
  def up
    create_table :d_objects_folders_users, id:false do |t|
      t.integer :d_objects_folder_id
      t.integer :user_id, null:false
      t.string :pattern, limit:128
      t.string :mode, limit:2, null:false
    end
    # ALTER TABLE d_objects_folders_users add primary key(d_objects_folder_id,user_id);
    execute <<-SQL
      CREATE UNIQUE INDEX d_objects_folders_users_idx on d_objects_folders_users(d_objects_folder_id,user_id) 
                              WHERE d_objects_folder_id NOTNULL;
      CREATE UNIQUE INDEX d_objects_folders_users_pattern_idx on d_objects_folders_users(pattern,user_id) 
                              WHERE pattern NOTNULL;
      ALTER TABLE ONLY d_objects_folders_users
        ADD CONSTRAINT d_objects_folder_id_fkey FOREIGN KEY (d_objects_folder_id)
           REFERENCES d_objects_folders(id) ON UPDATE CASCADE ON DELETE SET NULL;
      ALTER TABLE ONLY d_objects_folders_users
        ADD CONSTRAINT user_id_fkey FOREIGN KEY (user_id)
           REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;
      ALTER TABLE d_objects_folders_users ADD CONSTRAINT mode_check check (mode in ('ro','rw'));
    SQL
  end

  def down
    drop_table :d_objects_folders_users
  end
end
