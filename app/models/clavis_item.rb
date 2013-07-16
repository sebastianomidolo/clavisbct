class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  has_many :talking_books, :foreign_key=>'n', :primary_key=>'collocation'
  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id
  has_many :attachments, :as => :attachable

  def to_label
    if self.clavis_manifestation.nil?
      self.collocazione
    else
      "#{self.collocazione} (#{self.clavis_manifestation.title.strip})"
    end
  end

  def view
    extra = self['value_label'].nil? ? '' : "#{self['value_label']}: "
    "#{extra}#{self.title.strip}#{self.collocazione}"
  end


  def collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
  end

  def clavis_url(mode=:show)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    r=''
    if mode==:show
      r="#{host}/index.php?page=Catalog.ItemViewPage&id=#{self.id}"
    end
    if mode==:loan
      r="#{host}/index.php?page=Circulation.NewLoan&itemId=#{self.id}"
    end
    r
  end


end
