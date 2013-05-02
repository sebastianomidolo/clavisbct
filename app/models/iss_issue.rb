class IssIssue < ActiveRecord::Base
  self.table_name='iss.issues'

  belongs_to :journal, :class_name=>'IssJournal'
  has_many :articles, :class_name=>'IssArticle', :foreign_key=>'issue_id', :order=>:position
end

