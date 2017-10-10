# -*- coding: utf-8 -*-
class Container < ActiveRecord::Base
  attr_accessible :item_title, :closed, :label, :library_id, :prenotabile

  has_many :container_items, order: 'item_title',include: [:clavis_item,:clavis_manifestation]
  belongs_to :clavis_library, foreign_key: :library_id, primary_key: :library_id

  validates :label, presence: true, uniqueness: true
  validates :clavis_library, presence: true

  validates :label, format: { with: /\A[A-Z]+\d+\Z/,
    message: "deve iniziare con lettere maiuscole e finire con un numero" }

  def info
    "#{self.label}, #{self.closed? ? 'Chiuso' : 'Aperto'}, #{self.clavis_library.description}"
  end

  def elements
    sql=%Q{with x as
        (
          select collocazione,titolo,null as item_id,0 as manifestation_id,
            NULL as container_item_id, NULL as container_item_title,
             id as extra_card_id
             from #{ExtraCard.table_name} where container_id = #{self.id} and not deleted
          UNION
          select cc.collocazione,c.item_title as titolo, ci.item_id, ci.manifestation_id,
            c.id as container_item_id, c.item_title,
             NULL as extra_card_id
             from container_items c join clavis.item ci using(item_id)
              join clavis.collocazioni cc using(item_id) where c.container_id=#{self.id}
        ) select * from x order by espandi_collocazione(collocazione);}
    ActiveRecord::Base.connection.execute(sql).to_a
  end

  def Container.barcodes
    sql="select distinct barcode from container_items cni join clavis.item ci using(item_id) where barcode notnull and opac_visible='1'"
    ActiveRecord::Base.connection.execute(sql).to_a
  end

  def Container.lista
    sql=%Q{SELECT c.id,c.label,c.closed,l.library_id,l.label AS description
      FROM containers c LEFT JOIN clavis.library l USING(library_id)
        ORDER BY substr(c.label,0,2), regexp_replace(c.label,'([A-Z]+)','')::integer}
    Container.find_by_sql(sql)
  end

end
