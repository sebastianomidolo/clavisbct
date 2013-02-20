# lastmod 20 febbraio 2013

class ClavisIssue < ActiveRecord::Base
  self.table_name='clavis.issue'
  self.primary_key = 'issue_id'

  belongs_to :clavis_manifestation, :foreign_key=>:issue_id

end
