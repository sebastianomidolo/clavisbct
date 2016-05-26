class OmekaCollection < OmekaRecord
  self.table_name='omeka.collections'
  has_many :items, foreign_key: 'collection_id', class_name:OmekaItem
  has_many :element_texts, foreign_key:'record_id', conditions:"record_type='Collection'", class_name:OmekaElementText
end
