# lastmod 25 gennaio 2013
# lastmod 12 dicembre 2012

class ClavisItem < ActiveRecord::Base
  set_table_name 'clavis.item'
  set_primary_key 'item_id'

  def collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
  end
end
