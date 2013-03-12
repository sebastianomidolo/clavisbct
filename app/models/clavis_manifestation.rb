# lastmod 20 febbraio 2013

class ClavisManifestation < ActiveRecord::Base
  # attr_accessible :title, :body
  self.table_name = 'clavis.manifestation'
  self.primary_key = 'manifestation_id'

  has_many :clavis_items, :foreign_key=>'manifestation_id'
  has_many :clavis_issues, :foreign_key=>'manifestation_id'

  def ultimi_fascicoli
    self.clavis_issues.all(:order=>'issue_id desc', :limit=>10)
  end

  def clavis_url
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Catalog.Record&manifestationId=#{self.id}"
  end

  def thebid
    self.bid.blank? ? 'nobid' : self.bid
  end

end
