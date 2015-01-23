class ExtraCard < ActiveRecord::Base
  attr_accessible :titolo, :collocazione, :inventory_serie_id, :inventory_number, :deleted, :owner_library_id
  self.table_name='topografico_non_in_clavis'

  belongs_to :created_by, class_name: 'User', foreign_key: :created_by
  belongs_to :updated_by, class_name: 'User', foreign_key: :updated_by

  validates :titolo, :collocazione, presence: true

  def clavis_item
    ClavisItem.find_by_custom_field3_and_home_library_id(self.id.to_s,-1)
  end

  def serieinv
    "#{self.inventory_serie_id}-#{inventory_number}"
  end

end
