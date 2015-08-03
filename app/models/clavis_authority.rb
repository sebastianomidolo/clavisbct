class ClavisAuthority < ActiveRecord::Base
  self.table_name = 'clavis.authority'  

  belongs_to :clavis_authority, :foreign_key=>:parent_id
  has_many :bncf_terms, primary_key:'full_text', foreign_key:'term'

  def letterebct_person
    sql=%Q{select p.* from clavis.authority ca join letterebct.people p on(ca.full_text=p.denominazione) where ca.authority_type='P' and ca.full_text=#{self.connection.quote(self.full_text)}}
    self.connection.execute(sql).to_a.first
  end

  def subjects(subject_class=nil)
    subject_class = subject_class.nil? ? '' : "AND s.clavis_subject_class='#{subject_class}'"
    sql=%Q{SELECT s.clavis_subject_class as subject_class,ca.full_text,ca.authority_id,s.id AS subject_id,count(*) AS titoli
   FROM clavis.l_subject ls JOIN clavis.authority ca ON(ls.subject_id=ca.authority_id)
    LEFT JOIN clavis.l_authority_manifestation am ON(am.authority_id=ca.authority_id)
    JOIN public.subjects s ON(s.clavis_authority_id=ca.authority_id AND s.clavis_subject_class=ca.subject_class)
  WHERE ls.position=0 AND ls.authority_id=#{self.id}#{subject_class}
   GROUP BY ca.subject_class,ca.full_text,ca.authority_id,s.id ORDER BY ca.sort_text,ca.subject_class}
    puts sql
    ClavisAuthority.connection.execute(sql).to_a
  end

  def clavis_url(mode=:show)
    ClavisAuthority.clavis_url(self.id,mode)
  end

  def ClavisAuthority.clavis_url(id,mode=:show)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    r=''
    if mode==:show
      r="#{host}/index.php?page=Catalog.AuthorityViewPage&id=#{id}"
    end
    if mode==:edit
      r="#{host}/index.php?page=Catalog.AuthorityEditPage&id=#{id}"
    end
    r
  end

  def ClavisAuthority.list
    sql=%Q{SELECT lv.value_key AS authority_type,lv.value_label as label
             FROM clavis.lookup_value lv WHERE value_language='it_IT' AND value_class = 'AUTHTYPE'
              ORDER by value_label}
    ClavisAuthority.connection.execute(sql).collect{|x| [x['label'],x['authority_type']]}
  end

end
