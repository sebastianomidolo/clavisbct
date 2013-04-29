class CreateDObjects < ActiveRecord::Migration
  def up
    create_table :d_objects do |t|
      t.string :filename, :limit=>2048
      t.xml :tags
      t.decimal :bfilesize, :precision=>15, :scale=>0
      t.string  :mime_type, :limit=>96
      t.datetime :f_ctime
      t.datetime :f_mtime
      t.datetime :f_atime
    end
  end
  def down
    drop_table :d_objects
  end
end
