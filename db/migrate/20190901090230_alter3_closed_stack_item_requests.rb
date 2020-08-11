class Alter3ClosedStackItemRequests < ActiveRecord::Migration
  def up
    add_column :closed_stack_item_requests, :confirmed_by, :integer
    execute <<-SQL
      ALTER TABLE closed_stack_item_requests ADD CONSTRAINT created_by_id_fkey
        FOREIGN KEY(created_by) REFERENCES users
         ON UPDATE CASCADE ON DELETE SET NULL;
      ALTER TABLE closed_stack_item_requests ADD CONSTRAINT confirmed_by_id_fkey
        FOREIGN KEY(confirmed_by) REFERENCES users
         ON UPDATE CASCADE ON DELETE SET NULL;
    SQL
  end
  def down
    execute <<-SQL
      ALTER TABLE closed_stack_item_requests DROP CONSTRAINT created_by_id_fkey;
      ALTER TABLE closed_stack_item_requests DROP CONSTRAINT confirmed_by_id_fkey;
    SQL
    remove_column :closed_stack_item_requests, :confirmed_by
  end
end
