class AlterContainerItems < ActiveRecord::Migration
  def up
    add_column :container_items, :created_by, :integer
    add_column :container_items, :container_id, :integer
    add_column :containers, :closed, :boolean, default: false
    add_column :containers, :created_by, :integer
    execute <<-SQL
      ALTER TABLE container_items ADD CONSTRAINT user_id_fkey
        FOREIGN KEY(created_by) REFERENCES users
         ON UPDATE CASCADE ON DELETE SET NULL;
      UPDATE container_items ci SET created_by = u.id FROM users u WHERE u.google_doc_key=ci.google_doc_key;
      UPDATE container_items ci SET container_id = c.id FROM containers c WHERE c.label=ci.label;
      UPDATE containers SET closed=true;
      CREATE UNIQUE INDEX containers_label_idx ON containers (label);
      ALTER TABLE containers ALTER COLUMN label SET NOT NULL;
    SQL
  end

  def down
    remove_column :container_items, :created_by
    remove_column :container_items, :container_id
    remove_column :containers, :closed
    remove_column :containers, :created_by
    execute "DROP INDEX containers_label_idx"
  end
end
