class Subject < ActiveRecord::Base
  attr_accessible :heading

  def seealso
    sql="select s2.* from subjects s1 join subject_subject ss on(s1.id=ss.s1_id) join subjects s2 on(s2.id=ss.s2_id) where ss.linktype='sa' and s1.id=#{self.id}"
    Subject.find_by_sql(sql)
  end

  def bt
    sql="select s2.* from subjects s1 join subject_subject ss on(s1.id=ss.s1_id) join subjects s2 on(s2.id=ss.s2_id) where ss.linktype='bt' and s1.id=#{self.id}"
    Subject.find_by_sql(sql)
  end

  

end
