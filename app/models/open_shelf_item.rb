class OpenShelfItem < ActiveRecord::Base
  self.primary_key = 'item_id'
  attr_accessible :item_id
  belongs_to :clavis_item, foreign_key:'item_id'
end
