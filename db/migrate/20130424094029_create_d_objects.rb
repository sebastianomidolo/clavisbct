class CreateDObjects < ActiveRecord::Migration
  def up
    create_table :d_objects do |t|
      t.string :drive, :limit=>48
      t.string :container, :limit=>240
      t.string :filepath, :limit=>320
      t.xml :tags
      t.decimal :bfilesize, :precision=>15, :scale=>0
      t.string  :mime_type, :limit=>24
      t.datetime :f_ctime
      t.datetime :f_mtime
    end
  end
  def down
    drop_table :d_objects
  end
end
