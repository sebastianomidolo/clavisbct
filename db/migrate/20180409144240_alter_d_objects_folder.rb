class AlterDObjectsFolder < ActiveRecord::Migration
  def up
    add_column :d_objects_folders, :access_right_id, :integer
    execute %Q{ALTER TABLE d_objects_folders ADD CONSTRAINT access_right_id_fkey FOREIGN KEY (access_right_id)
               REFERENCES access_rights ON UPDATE CASCADE ON DELETE SET NULL}
  end

  def down
    remove_column :d_objects_folders, :access_right_id
  end
end
