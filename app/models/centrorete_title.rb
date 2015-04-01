class CentroreteTitle < ActiveRecord::Base
  attr_accessible :titolo
  self.table_name = 'cr_acquisti.acquisti'

  def clavis_manifestation
    sql = %Q{SELECT cm.* FROM centrorete_clavis cc left join clavis.manifestation cm using(manifestation_id) WHERE cc.id=#{self.id}}
    r=ClavisManifestation.find_by_sql(sql)
    r.size==0 ? nil : r.first
  end
end

