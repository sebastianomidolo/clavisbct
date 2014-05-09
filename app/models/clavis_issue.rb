# lastmod 20 febbraio 2013

class ClavisIssue < ActiveRecord::Base
  self.table_name='clavis.issue'
  self.primary_key = 'issue_id'

  attr_accessible :manifestation_id, :issue_id, :issue_volume

  belongs_to :clavis_manifestation, :foreign_key=>:issue_id

end
