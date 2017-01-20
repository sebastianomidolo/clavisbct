class CreateWorkStations < ActiveRecord::Migration
  def change
    create_table :work_stations do |t|
      t.integer :id
      t.integer :clavis_library_id
      t.string :processor, limit:2
      t.string :location, limit:80
    end
    execute <<-SQL
      ALTER TABLE work_stations ALTER COLUMN id DROP DEFAULT;
    SQL
  end
end
