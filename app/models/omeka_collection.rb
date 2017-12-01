class OmekaCollection < OmekaRecord
  self.table_name='bcteka.collections'
  has_many :items, foreign_key: 'collection_id', class_name:OmekaItem
  has_many :element_texts, foreign_key:'record_id', conditions:"record_type='Collection'", class_name:OmekaElementText

  def parent_collection
    sql=%Q{SELECT c.* FROM bcteka.collection_trees ct JOIN bcteka.collections c ON(c.id=ct.parent_collection_id)
            WHERE ct.collection_id=#{self.id} AND ct.parent_collection_id!=0;}
    OmekaCollection.find_by_sql(sql).first
  end

  def ancestors(self_include=false)
    c=self
    res=[]
    while !c.parent_collection.nil? do
      puts "c: {c.id}"
      c=c.parent_collection
      res << c
    end
    res.reverse!
    res << self if self_include
    res
  end

  def omeka_url
    "https://bcteka.comperio.it/collections/show/#{self.id}"
  end


  def OmekaCollection.sql(parent_collection=0)
    filter = parent_collection.nil? ? '' : "WHERE ct.parent_collection_id=#{parent_collection.to_i}"
    %Q{SELECT parent_collection_id,ct.collection_id as id,et.text as title
       FROM bcteka.collection_trees ct JOIN bcteka.element_texts et
          ON(et.record_id=ct.collection_id AND et.record_type='Collection' AND element_id=50)
      #{filter} order by parent_collection_id,text;}
  end

  def OmekaCollection.options_for_select(parent_collection=0)
    sql=OmekaCollection.sql(parent_collection)
    OmekaCollection.connection.execute(sql).collect {|c| [c['title'],c['id']]}
  end

  def OmekaCollection.collections_list(parent_collection=0)
    OmekaCollection.find_by_sql(OmekaCollection.sql(parent_collection))
  end

end
