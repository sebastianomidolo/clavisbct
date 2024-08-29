# -*- coding: utf-8 -*-
class BioIconograficoNamespace < ActiveRecord::Base
  self.table_name='public.bio_icon_namespaces'
  self.primary_key = 'label'
  attr_accessible :baseurl, :descr, :label, :published, :title, :clavis_username

  attr_accessor :clavis_username

  before_save :check_record
  
  validates :label, presence: true, uniqueness: true

  def users
    sql=%Q{SELECT u.*,cl.lastname,cl.name FROM public.bio_icon_namespaces_users nu JOIN public.users u on(u.id=nu.user_id) 
      LEFT JOIN clavis.librarian cl on(cl.username=u.email) WHERE nu.label=#{self.connection.quote(self.label)}
      order by cl.lastname}
    User.find_by_sql(sql)
  end

  def check_record
    self.label = nil if self.label.blank?
  end

  def add_user(clavis_username)
    sql = %Q{
       insert into public.bio_icon_namespaces_users(label,user_id)
        (select '#{self.label}',u.id from public.users u join clavis.librarian cl on (cl.username=u.email)
           where cl.username=#{self.connection.quote(clavis_username)})
        on conflict(label,user_id) do nothing;
      }
    self.connection.execute(sql)
  end

  def delete_user(user_id)
    sql = %Q{delete from public.bio_icon_namespaces_users where user_id=#{user_id} and label = '#{self.label}'}
    self.connection.execute(sql)
  end

  def numfiles(params={})
    cond = params[:lettera].blank? ? '' : "AND lettera = #{self.connection.quote(params[:lettera])}"
    sql="select count(*) from bio_iconografico_cards where namespace = '#{self.label}' #{cond}"
    self.connection.execute(sql).first['count'].to_i
  end

  def total_filesize(params={})
    cond = params[:lettera].blank? ? '' : "AND lettera = #{self.connection.quote(params[:lettera])}"
    sql=%Q{select sum(o.bfilesize) as size from bio_iconografico_cards b join d_objects o using (id)
                WHERE b.namespace = '#{self.label}' #{cond}}
    self.connection.execute(sql).first['size'].to_i
  end

  def doppi
    sql=%Q{select o.* from bio_iconografico_cards b join d_objects o using(id) where b.id in (select unnest(array_agg(id)) as ids from bio_iconografico_cards
         where b.namespace = '#{self.label}' and numero>0 group by lettera,numero having count(*)>1) order by lettera,numero}
    puts sql
    # BioIconograficoNamespace.find_by_sql(sql)
  end

  def BioIconograficoNamespace.tutti(params, user=nil)
    self.find_by_sql(self.sql_for_tutti(params, user))
  end

  def BioIconograficoNamespace.sql_for_tutti(params,user=nil)
    %Q{select * from #{self.table_name} order by title}
  end

end
