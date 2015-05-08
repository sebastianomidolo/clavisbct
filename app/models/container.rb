class Container < ActiveRecord::Base
  attr_accessible :item_title, :closed, :label, :library_id

  has_many :container_items, order: 'row_number',include: [:clavis_item,:clavis_manifestation]
  belongs_to :clavis_library, foreign_key: :library_id, primary_key: :library_id

  validates :label, presence: true, uniqueness: true
  validates :clavis_library, presence: true

  def info
    "#{self.label}, #{self.closed? ? 'Chiuso' : 'Aperto'}, #{self.clavis_library.description}"
  end

  def Container.barcodes
    sql="select distinct barcode from container_items cni join clavis.item ci using(item_id) where barcode notnull and opac_visible='1'"
    ActiveRecord::Base.connection.execute(sql).to_a
  end

  def Container.lista
    sql=%Q{SELECT c.id,c.label,c.closed,l.library_id,l.label AS description,count(i) AS numvol
      FROM containers c LEFT JOIN clavis.library l USING(library_id) LEFT JOIN container_items i ON(c.id=i.container_id)
        GROUP BY c.id,c.label,c.closed,l.library_id,l.label
        ORDER BY regexp_replace(c.label,'([A-Z]+)','')::integer DESC}
    puts sql
    Container.find_by_sql(sql)
  end

end
