class IssPage < ActiveRecord::Base
  self.table_name='iss.pages'
  belongs_to :article, :class_name=>'IssArticle'

  has_many :attachments, :as => :attachable

  def to_label
    "Page #{self.pagenumber} => Articolo \"#{self.article.title}\", Rivista \"#{self.article.issue.journal.title}\""
  end
end
