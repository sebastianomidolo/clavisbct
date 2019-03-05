class Alter2ClosedStackItemRequests < ActiveRecord::Migration
  def up
    add_column :closed_stack_item_requests, :created_by, :integer
    add_column :closed_stack_item_requests, :archived, :boolean, null:false, default:false
    add_column :closed_stack_item_requests, :confirm_time, :timestamp
    add_column :closed_stack_item_requests, :print_time, :timestamp
  end

  def down
    remove_column :closed_stack_item_requests, [:created_by, :archived, :confirm_time, :print_time]
  end
end
