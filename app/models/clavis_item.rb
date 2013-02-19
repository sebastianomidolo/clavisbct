class ClavisItem < ActiveRecord::Base
  set_table_name 'clavis.item'
  set_primary_key 'item_id'

  def collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
  end
end
