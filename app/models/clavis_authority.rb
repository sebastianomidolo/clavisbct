class ClavisAuthority < ActiveRecord::Base
  self.table_name = 'clavis.authority'  

  belongs_to :clavis_authority, :foreign_key=>:parent_id
  has_many :bncf_terms, primary_key:'full_text', foreign_key:'term'
  attr_accessible :full_text

  def to_label
    "#{authority_type} - #{full_text} - #{self.id}"
  end

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

  def dividi_soggetto
    s1,s2 = self.full_text.split('|')
    return nil if s2.nil?
    # return [s1,s2]
    r1 = ClavisAuthority.find_or_create_by_full_text(s1)
    r2 = ClavisAuthority.find_or_create_by_full_text(s2)
    # [s1.strip,s2.strip]
    # [r1.full_text.strip,r2.full_text.strip]
    [r1.id,r2.id]
  end

  def l_authorities(direction)
    invers = direction=='up' ? 'down' : 'up'
    sql = %Q{select l.link_type,a.* from clavis.l_authority l join clavis.authority a on (a.authority_id=l.authority_id_#{invers})
            where l.authority_id_#{direction}=#{self.id};}
    puts sql
    ClavisAuthority.find_by_sql(sql)
  end

  def l_manifestations
    sql = %Q{select cm.* from clavis.manifestation cm join clavis.l_authority_manifestation l using(manifestation_id)
            where l.authority_id=#{self.id};}
    ClavisManifestation.find_by_sql(sql)
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

  def ClavisAuthority.dupl(authority_type)
    sql=%Q{select full_text as heading,array_agg(authority_id order by authority_id) as ids,count(*) from clavis.authority where 
 authority_type='#{authority_type}' and full_text!='' group by full_text having count(*)>1 order by count(*) desc, full_text}
    # self.connection.execute(sql).to_a
    self.find_by_sql sql
  end

  def ClavisAuthority.list(include_all=:false)
    sql=%Q{SELECT lv.value_key AS authority_type,lv.value_label as label
             FROM clavis.lookup_value lv WHERE value_language='it_IT' AND value_class = 'AUTHTYPE'
              ORDER by value_label}
    r=ClavisAuthority.connection.execute(sql).collect{|x| [x['label'],x['authority_type']]}
    r << ['Tutte le tipologie',:all]
  end

end
