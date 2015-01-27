class CreateOpenShelfItems < ActiveRecord::Migration
  def change
    create_table :open_shelf_items, id:false do |t|
      t.integer :item_id, null:false
      t.integer :created_by
    end
    add_index :open_shelf_items, :item_id, :unique=>true
  end
end
