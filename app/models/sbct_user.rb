# coding: utf-8

class SbctUser < ActiveRecord::Base
  self.table_name='sbct_acquisti.pac_users'
  self.primary_key = 'user_id'
  has_many :sbct_lists, foreign_key:'owner_id'

  def to_label
    "#{name} #{lastname} (#{username}) - #{library_name}"
  end

  def roles
    user.roles
  end

  def user
    User.find(self.id)
  end

  def create_private_list
    return if self.sbct_lists.size>0
    cl = self.user.clavis_librarian
    label = "#{cl.name} #{lastname[0..0]}."
    label = "#{self.connection.quote(label)}"
    sql = %Q{INSERT INTO #{SbctList.table_name} (label,owner_id) VALUES(#{label},#{self.id})}
    self.connection.execute(sql)
  end

  def items_selection_report
    sql=%Q{select sum(numcopie) as numcopie,sum(prezzo*numcopie) as prezzo from sbct_acquisti.copie cp
       where cp.created_by=#{self.id} and cp.order_status='S'}
    self.connection.execute(sql)
  end
  
  def SbctUser.user_select
    sql=%Q{select * from sbct_acquisti.pac_users order by lastname}
    self.connection.execute(sql).collect {|i| [ "#{i['name']} #{i['lastname']} (#{i['user_id']})",i['user_id'] ]}
  end

end
