# lastmod 21 febbraio 2013

class ClavisPatron < ActiveRecord::Base
  self.table_name='clavis.patron'
  self.primary_key='patron_id'

  has_many :loans, :class_name=>'ClavisLoan', :foreign_key=>'patron_id'
end
