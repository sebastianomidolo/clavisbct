class AddRfidSummary < ActiveRecord::Migration
  def up
    create_table :rfid_summary, id:false do |t|
      t.integer :library_id, null:false
      t.date    :snapshot_date, null:false
      t.integer :tagged_count, null:false
    end
  end

  def down
    drop_table :rfid_summary
  end
end
