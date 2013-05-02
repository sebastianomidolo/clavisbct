class IssArticle < ActiveRecord::Base
  self.table_name='iss.articles'
  belongs_to :issue, :class_name=>'IssIssue'
  has_many :pages, :class_name=>'IssPage', :order=>:position, :foreign_key=>:article_id
end
