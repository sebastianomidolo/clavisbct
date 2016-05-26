class OmekaItem < OmekaRecord
  self.table_name='omeka.items'
  has_many :files, foreign_key: 'item_id', class_name:OmekaFile
  has_many :element_texts, foreign_key:'record_id', conditions:"record_type='Item'", class_name:OmekaElementText
  belongs_to :collection, foreign_key: 'collection_id', class_name:OmekaCollection

  def OmekaItem.create(collection_id)
    sql=%Q{INSERT INTO #{self.table_name} ("added", "collection_id", "featured", "item_type_id", "modified", "owner_id", "public") VALUES (now(), #{collection_id}, false, NULL, now(), 1, false)}
    puts sql
    self.connection.execute sql
    self.last
  end
end
