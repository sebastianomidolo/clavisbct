class Subject < ActiveRecord::Base
  attr_accessible :heading, :clavis_subject_class, :inbct

  has_many :bncf_terms, foreign_key:'term', primary_key:'heading'

  has_many :clavis_l_authority_manifestations, :foreign_key=>'authority_id', :primary_key=>'clavis_authority_id'
  has_many :clavis_manifestations, :through=>:clavis_l_authority_manifestations, :order=>'sort_text'
  belongs_to :clavis_authority

  def to_html
    self.heading.sub('<','&lt;').sub('>','&gt;')
  end

  def seealso
    sql=%Q{select s2.*,ss.linknote from subjects s1 join subject_subject ss on(s1.id=ss.s1_id)
 join subjects s2 on(s2.id=ss.s2_id) where ss.linktype='sa' and s1.id=#{self.id} ORDER BY ss.seq}
    puts sql
    Subject.find_by_sql(sql)
  end

  def see
    sql=%Q{select s1.*,ss.linknote from subjects s1 join subject_subject ss on(s1.id=ss.s1_id)
 join subjects s2 on(s2.id=ss.s2_id) where ss.linktype='see' and s2.id=#{self.id} ORDER BY ss.seq}
    Subject.find_by_sql(sql)
  end

  def use_for
    sql=%Q{select s2.*,ss.linknote from subjects s1 join subject_subject ss on(s1.id=ss.s1_id)
 join subjects s2 on(s2.id=ss.s2_id) where ss.linktype='see' and s1.id=#{self.id} ORDER BY ss.seq}
    Subject.find_by_sql(sql)
  end


  def bt
    sql="select s2.*,ss.linknote from subjects s1 join subject_subject ss on(s1.id=ss.s1_id) join subjects s2 on(s2.id=ss.s2_id) where ss.linktype='bt' and s1.id=#{self.id} ORDER BY s2.heading::char"
    Subject.find_by_sql(sql)
  end

  def suddivisioni
    sql="select s2.*,ss.linknote from subjects s1 join subject_subject ss on(s1.id=ss.s1_id) join subjects s2 on(s2.id=ss.s2_id) where ss.linktype='sub' and s1.id=#{self.id} ORDER BY ss.seq"
    Subject.find_by_sql(sql)
  end

  def suddivisione_di
    sql=%Q{select s.*,ss.linknote from subject_subject ss join subjects s on(s.id=ss.s1_id) where s2_id = #{self.id} and linktype='sub'}
    Subject.find_by_sql(sql).first
  end

  def clavis_authority_other_subjects
    return [] if self.clavis_authority.nil?
    return [] if self.clavis_authority.clavis_authority.nil?
    self.clavis_authority.clavis_authority.subjects(self.clavis_subject_class)
  end

  def Subject.clavis_subject_classes
    sql=%Q{select clavis_subject_class csc,count(*) as cnt from subjects group by clavis_subject_class order by lower(clavis_subject_class)}
    self.connection.execute(sql).collect {|i| ["#{i['csc']} (#{i['cnt']})",i['csc']]}
  end

  def Subject.duplicate_terms
    sql=%Q{with doppie as
      (select full_text as heading,array_agg(subject_class order by subject_class,authority_id) as subject_classes,
        array_agg(authority_id order by subject_class,authority_id) as authority_ids,count(*) from clavis.authority
         where full_text notnull and subject_class in('FI','MSO','ACT')
        group by full_text having count(*)>1)
      select * from doppie where 'ACT' = ANY(subject_classes) OR 'MSO' = ANY(subject_classes)
        order by heading;}
    self.connection.execute(sql).to_a
  end
end
