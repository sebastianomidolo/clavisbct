class AccessRight < ActiveRecord::Base
  has_many :d_objects
  def to_label
    self.label
  end

  def AccessRight.options_for_select
    sql=%Q{select code,label from access_rights order by code}
    self.connection.execute(sql).collect {|i| ["#{i['label']}",i['code']]}
  end
end
