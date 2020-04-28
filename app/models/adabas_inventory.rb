class AdabasInventory < ActiveRecord::Base
  self.table_name='adabas_2011_registro_inventari'
  belongs_to :clavis_library, foreign_key:'library_id'
end
