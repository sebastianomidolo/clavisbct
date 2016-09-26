class DngMember < ActiveRecord::Base
  self.table_name='dng."Member"'
  self.primary_key = 'ID'

  def clavis_patron
    sql=%Q{SELECT p.* FROM clavis.patron p JOIN dng."Member" m USING(patron_id) WHERE m."ID"=#{self.id};}
    ClavisPatron.find_by_sql(sql).first
  end
end
