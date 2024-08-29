class SpUser < ActiveRecord::Base
  self.table_name='sp.sp_users'
  self.primary_keys = :bibliography_id, :user_id

  attr_accessible :bibliography_id, :user_id, :auth

  def SpUser.enabled_users
    sql = %Q{select u.id,u.email,cl.librarian_id,cl.name,cl.lastname,count(b) as bibliographies_count
   from public.roles_users ru join roles r on(r.id=ru.role_id) 
      join public.users u on (u.id=ru.user_id)
      left join sp.sp_users spu using(user_id)
      left join clavis.librarian cl on (cl.username=u.email)
      left join sp.sp_bibliographies b on(b.id=spu.bibliography_id)
     where r.name='SpBibliographyUser' group by u.id,cl.librarian_id order by cl.lastname,cl.name}
    User.find_by_sql(sql)
  end

  def SpUser.managed_bibliographies
    SpBibliography.find_by_sql('select distinct b.* from sp.sp_users spu join sp.sp_bibliographies b on (b.id=spu.bibliography_id) order by b.title')
  end

end
