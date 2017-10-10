class AlterExtraCards < ActiveRecord::Migration
  def up
    add_column ExtraCard.table_name, :container_id, :integer
    execute(%{ALTER TABLE #{ExtraCard.table_name} ADD CONSTRAINT container_id_fkey
        FOREIGN KEY(container_id) REFERENCES containers
         ON UPDATE CASCADE ON DELETE SET NULL;})
  end

  def down
    remove_column ExtraCard.table_name, :container_id
  end
end


