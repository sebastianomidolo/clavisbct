class BncfTerm < ActiveRecord::Base
  attr_accessible :term, :parent_id
  has_many :other_terms, class_name: "BncfTerm", foreign_key: 'parent_id'
  belongs_to :parent_term, class_name: "BncfTerm", foreign_key: 'parent_id'

  has_many :subjects, foreign_key:'heading', primary_key:'term'

  def BncfTerm.obsoleteTerms
    sql=%Q{select ca.authority_id,ns1.term as "non_preferito",ns2.term as "preferito",ns2.bncf_id,
       ns1.id as "nonpref_id", ns2.id as "pref_id", ca.subject_class
    from clavis.authority ca join bncf_terms ns1 on(ns1.term=ca.full_text)
   left join bncf_terms ns2 on(ns2.id=ns1.parent_id)
 where authority_type = 'A' and authority_rectype in ('k','x')
  and ns1.termtype='obsoleteTerm' order by ns1.term;}
    BncfTerm.connection.execute(sql)
  end

  def BncfTerm.missingTerms(starts_with=nil)
    if starts_with.blank?
      sql=%Q{select * from soggetti_non_presenti_in_nuovo_soggettario order by random() limit 20}
    else
      sql=%Q{select * from soggetti_non_presenti_in_nuovo_soggettario where heading ~* '^#{starts_with}'}
    end
    BncfTerm.connection.execute(sql)
  end

  def BncfTerm.url(id)
    "http://thes.bncf.firenze.sbn.it/termine.php?id=#{id}"
  end
end
