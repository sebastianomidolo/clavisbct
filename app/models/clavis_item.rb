class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  has_many :talking_books, :foreign_key=>'n', :primary_key=>'collocation'


  belongs_to :clavis_manifestation, :foreign_key=>:item_id

  def collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
  end


  def clavis_url(mode=:show)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Catalog.ItemViewPage&id=#{self.id}"
  end

end
