class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  attr_accessible :title, :owner_library_id, :item_status, :opac_visible, :manifestation_id,
                   :item_media, :collocation, :inventory_number, :manifestation_dewey

  belongs_to :owner_library, class_name: 'ClavisLibrary', foreign_key: 'owner_library_id'

  has_many :talking_books, :foreign_key=>'n', :primary_key=>'collocation'
  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id
  has_many :attachments, :as => :attachable

  def to_label
    if self.clavis_manifestation.nil?
      self.la_collocazione
    else
      "#{self.la_collocazione} (#{self.clavis_manifestation.title.strip})"
    end
  end

  def view
    extra = self['value_label'].nil? ? '' : "#{self['value_label']}: "
    "#{extra}#{self.title.strip}#{self.la_collocazione}"
  end

  def inventario
    "#{inventory_serie_id}-#{inventory_number}"
  end

  def la_collocazione
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

  def self.item_status
    sql=%Q{select value_label as label,value_key as key from clavis.lookup_value lv
  where value_language = 'it_IT' and value_class='ITEMSTATUS' order by value_key}
    self.connection.execute(sql).collect {|i| ["#{i['key']} - #{i['label']}",i['key']]}
  end

  def self.item_media
    sql=%Q{select value_label as label,value_key as key from clavis.lookup_value lv
  where value_language = 'it_IT' and value_class='ITEMMEDIATYPE' order by value_key}
    self.connection.execute(sql).collect {|i| ["#{i['key']} - #{i['label']}",i['key']]}
  end

  def self.owner_library
    sql=%Q{select library_id as key,label from clavis.library
      where library_status='A' AND library_internal='1' order by label}
    puts sql
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

end
