class Role < ActiveRecord::Base
  attr_accessible :name
  has_and_belongs_to_many :users
  has_and_belongs_to_many :services

  def servizi
    sql = %Q{select rs.service_id as id, replace(x.order_sequence, '_', '/') as name
    from public.roles_services rs
     join lateral (select * from public.view_services s where s.id=rs.service_id order by level desc limit 1) as x on true
    where rs.role_id = #{self.id}}
    Service.find_by_sql(sql)
  end
end
