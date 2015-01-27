class CreateOpenShelfItems < ActiveRecord::Migration
  def change
    create_table :open_shelf_items do |t|
      t.integer :item_id
      t.integer :created_by
      t.timestamps
    end
    add_index :open_shelf_items, :item_id, :unique=>true
  end
end
