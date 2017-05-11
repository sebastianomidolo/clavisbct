class AlterDObjectsAddFolderId < ActiveRecord::Migration
  def up
    add_column :d_objects, :d_objects_folder_id, :integer
  end

  def down
    remove_column :d_object, :d_objects_folder_id
  end
end
