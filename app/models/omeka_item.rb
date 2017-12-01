class OmekaItem < OmekaRecord
  self.table_name='bcteka.items'
  has_many :files, foreign_key: 'item_id', class_name:OmekaFile
  has_many :element_texts, foreign_key:'record_id', conditions:"record_type='Item'", class_name:OmekaElementText
  belongs_to :collection, foreign_key: 'collection_id', class_name:OmekaCollection

  def OmekaItem.create(collection_id)
    sql=%Q{INSERT INTO #{self.table_name} ("added", "collection_id", "featured", "item_type_id", "modified", "owner_id", "public") VALUES (now(), #{collection_id}, false, NULL, now(), 1, false)}
    puts sql
    self.connection.execute sql
    self.last
  end

  def omeka_url
    "http://bctwww.comperio.it/omeka/items/show/#{self.id}#?c=0&m=0&s=0&cv=0"
  end

end
