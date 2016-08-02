class CreateClosedStackItemRequests < ActiveRecord::Migration
  def up
    create_table :closed_stack_item_requests do |t|
      t.integer :id
      t.integer :item_id, null:false
      t.integer :patron_id, null:false
      t.integer :dng_session_id, null:false
      t.boolean :printed, null:false, default:false
      t.timestamp :request_time
    end
    sql=%Q{alter table closed_stack_item_requests alter COLUMN request_time set default now()}
    execute(sql)
  end
  def down
    drop_table :closed_stack_item_requests
  end
end
