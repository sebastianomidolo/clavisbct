class CreateXhrRequests < ActiveRecord::Migration
  def change
    create_table :xhr_requests do |t|
      t.string :ip
      t.string :target
      t.string :qs
      t.timestamp :timestamp
    end
  end
end
