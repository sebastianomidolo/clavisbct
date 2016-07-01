class ClavisLookupValue < ActiveRecord::Base
  self.table_name='clavis.lookup_value'
  self.primary_keys = [:value_key, :value_language, :value_class]

  set_inheritance_column :value_class

end

