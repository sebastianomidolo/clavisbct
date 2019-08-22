class IssIssue < ActiveRecord::Base
  self.table_name='iss.issues'

  belongs_to :journal, :class_name=>'IssJournal'
  has_many :articles, :class_name=>'IssArticle', :foreign_key=>'issue_id', :order=>:position

  def to_label
    "#{self.anno}/#{self.fascicolo}"
  end

  def numerazione
    r = "#{self.annata}, #{self.fascicolo}"
    r << " (#{self.info_fascicolo})" if self.info_fascicolo!=self.annata and !self.info_fascicolo.nil?
    r << " #{self.extra_info}"
    r
  end

  def cover_page
    sql = %Q{
      SELECT p.* FROM #{IssArticle.table_name} a, #{IssPage.table_name} p
       WHERE a.issue_id=#{self.id} AND p.article_id=a.id ORDER BY sequential limit 1;
    }
    p=IssPage.find_by_sql sql
    p.nil? ? nil : p[0]
  end
  def cover_image
    p=self.cover_page
    return nil if p.nil?
    p.pdf_2_jpg
  end

  
end

