class AlterDObjects < ActiveRecord::Migration
  def up
    add_column 'd_objects', :type, :string, :limit=>32
    add_index 'd_objects', :type
  end

  def down
    remove_column 'd_objects', :type
  end
end
