class AlterWorkStations < ActiveRecord::Migration
  def up
    add_column :work_stations, :monitor_id, :integer
  end

  def down
    remove_column :work_stations, :monitor_id
  end
end
