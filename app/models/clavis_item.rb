# lastmod 20 febbraio 2013

class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  belongs_to :clavis_manifestation, :foreign_key=>:item_id

  def collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
  end
end
