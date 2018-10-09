# RAILS_ENV=development rake db:migrate VERSION=20180409144240; RAILS_ENV=development rake db:migrate
class AlterClosedStackItemRequests < ActiveRecord::Migration
  def up
    add_column :closed_stack_item_requests, :daily_counter, :integer
  end

  def down
    remove_column :closed_stack_item_requests, :daily_counter
  end
end
