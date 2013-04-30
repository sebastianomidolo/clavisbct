class TalkingBook < ActiveRecord::Base
  self.table_name='libroparlato.catalogo'
  self.primary_key = 'id'
  has_one :clavis_item, :foreign_key=>'collocation', :primary_key=>'n'
  has_many :attachments, :as => :attachable

  def digitalized
    self.digitalizzato.nil? ? false : true
  end
end
