class IssArticle < ActiveRecord::Base
  self.table_name='iss.articles'
  belongs_to :issue, :class_name=>'IssIssue'
  has_many :pages, :class_name=>'IssPage', :order=>:position, :foreign_key=>:article_id


  def d_objects
    DObject.find_by_sql(%Q{select d.* from d_objects d join attachments a
      on(d.id=a.d_object_id) join iss.pages p
      on(p.id=a.attachable_id and attachable_type='IssPage') where p.id in
     (select id from iss.pages where article_id=#{self.id}) order by p."position";})
  end

end
