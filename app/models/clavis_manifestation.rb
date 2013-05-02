# lastmod 20 febbraio 2013

class ClavisManifestation < ActiveRecord::Base
  # attr_accessible :title, :body
  self.table_name = 'clavis.manifestation'
  self.primary_key = 'manifestation_id'


  # self.per_page = 10

  has_many :clavis_items, :foreign_key=>'manifestation_id'
  has_many :clavis_issues, :foreign_key=>'manifestation_id'

  has_many :attachments, :as => :attachable

  def to_label
    self.title
  end

  def ultimi_fascicoli
    self.clavis_issues.all(:order=>'issue_id desc', :limit=>10)
  end

  def clavis_url(mode=:show)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    r=''
    if mode==:show
      r="#{host}/index.php?page=Catalog.Record&manifestationId=#{self.id}"
    end
    if mode==:edit
      r="#{host}/index.php?page=Catalog.EditRecord&manifestationId=#{self.id}"
    end
    r
  end

  def thebid
    self.bid.blank? ? 'nobid' : "#{self.bid_source}-#{self.bid}"
  end

end
