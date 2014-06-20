class ClavisLibrary < ActiveRecord::Base
  self.table_name='clavis.library'
  self.primary_key = 'library_id'

  has_many :owned_items, class_name: 'ClavisItem', foreign_key: 'owner_library_id'
  has_many :ordini, foreign_key: 'library_id'

  def to_label
    self.label[0..40]
  end
  def nice_description
    self.description[5..100]
  end
  
end
