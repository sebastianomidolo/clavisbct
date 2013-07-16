class CreateDngSessions < ActiveRecord::Migration
  def up
    create_table :dng_sessions do |t|
      t.string :client_ip, :limit=>128
      t.datetime :login_time
      t.integer :patron_id, :null=>false
    end
  end
  def down
    drop_table :dng_sessions
  end

end
