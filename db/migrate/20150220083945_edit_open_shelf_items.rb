#              Table "clavis.library_value"
#       Column      |          Type          | Modifiers 
# ------------------+------------------------+-----------
#  value_key        | character varying(64)  | not null    (diventa "os_section")
#  value_class      | character varying(64)  | not null
#  value_library_id | integer                | not null
#  value_label      | character varying(255) | not null
# Indexes:
#     "library_value_pkey" PRIMARY KEY, btree (value_key, value_class, value_library_id)
#
# value_library_id corrisponde a owner_library_id dalla tabella clavis.item referenziata da item_id
# value_class e', in questo contesto, sempre uguale a 'ITEMSECTION'

class EditOpenShelfItems < ActiveRecord::Migration
  def up
    add_column :open_shelf_items, :os_section, :string, :limit=>64
  end

  def down
    remove_column :open_shelf_items, :section
  end
end
