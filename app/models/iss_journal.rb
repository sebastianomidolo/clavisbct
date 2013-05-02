class IssJournal < ActiveRecord::Base
  self.table_name='iss.journals'

  has_many :issues, :class_name=>'IssIssue', :foreign_key=>:journal_id, :order=>:position
end

