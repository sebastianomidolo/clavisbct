class CreateContainers < ActiveRecord::Migration
  def change
    create_table :containers do |t|
      t.string  :label, :limit=>16
      t.integer :library_id
    end
    create_table :container_items do |t|
      t.string  :label, :limit=>16
      t.integer :row_number
      t.integer :manifestation_id
      t.integer :item_id
      t.integer :consistency_note_id
      t.integer :library_id
      t.text :item_title
      t.string  :google_doc_key
    end

    add_column :users, :google_doc_key, :string
    execute(%Q{
      update users set google_doc_key = '1dKUg08NvSWQmOy0oJ6lKsagHFIDi4bbkeqKbJgsBf9k' where email='civ';
      update users set google_doc_key = '1aSJzKCI1_WlimHWtbgd5LircGAkEOrpCK90sH0n9ySs' where email='copat1';
      update users set google_doc_key = '1150XuZU2DcxiYc7URUKMYpgoVwmRMcpahSr1dAAmvMY' where email='copat2';
      update users set google_doc_key = '1XuRHleKDxgo_LtO4kGxaWEpxuNMxwIqN_7-gPuM9v9o' where email='copat3';
    })
  end
end
