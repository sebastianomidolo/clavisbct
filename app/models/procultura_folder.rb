class ProculturaFolder < ActiveRecord::Base
  self.table_name = 'procultura.folders'
  attr_accessible :label
  has_many :cards, :class_name=>'ProculturaCard', :foreign_key=>'folder_id', :order=>'lower(heading)'
  has_many :cards, :class_name=>'ProculturaCard', :foreign_key=>'folder_id', :order=>'id'
  belongs_to :archive, :class_name=>'ProculturaArchive'

  def schede
    sql = %Q{SELECT c.heading,count(*),array_agg(c.id) AS ids
        FROM procultura.folders f JOIN procultura.cards c
         ON(c.folder_id=f.id)
       WHERE f.id=#{self.id} group by c.heading order by lower(heading)}
    ProculturaCard.find_by_sql(sql)
  end

end
