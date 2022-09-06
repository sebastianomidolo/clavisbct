# coding: utf-8
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :registerable

  devise :database_authenticatable,:registerable, :recoverable, :rememberable, :trackable, :validatable
  # devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :encrypted_password, :created_at, :updated_at

  has_and_belongs_to_many :roles

  has_and_belongs_to_many :sp_bibliographies, :join_table=>'sp.sp_users', association_foreign_key:'bibliography_id', order:'title'

  def role?(role)
    return !!self.roles.find_by_name(role.to_s.camelize)
  end

  def to_label
    "#{self.name} #{self.lastname}"
  end

  def clavis_librarian
    ClavisLibrarian.find_by_username(self.email)
  end

  def sbct_budgets
    libraries=self.clavis_libraries.collect {|l| l.id}
    sql=%Q{
      select b.*,bl.clavis_library_id as library_id from sbct_acquisti.budgets b join sbct_acquisti.l_budgets_libraries bl using(budget_id)
        where not b.locked and clavis_library_id in (#{libraries.join(',')}) order by b.label;
    }
    puts sql
    SbctBudget.find_by_sql(sql)
  end

  def clavis_libraries
    self.clavis_librarian.clavis_libraries
  end
  
  def clavis_libraries_sigle
    ids=self.clavis_libraries.collect {|l| l.id}
    s=ClavisLibrary.library_ids_to_siglebct(ids)
    s= s.reject { |c| c.empty? }
    s.sort.join(', ')
    s.sort
  end

  def User.add_clavis_librarian(librarian_id, roles_array=[])
    if !ClavisLibrarian.exists?(librarian_id)
      puts "non esiste ClavisLibrarian con librarian_id = #{librarian_id}"
      return nil
    end
    cl = ClavisLibrarian.find(librarian_id)
    puts "Cerco utente con email/username #{cl.username}"
    u = User.find_by_email(cl.username)
    return u if !u.nil?
    email = "#{cl.username}@comperio.it"
    pwd = 'bctorino'
    puts "creazione utente #{librarian_id} con username #{cl.username}"
    roles_array.each do |role_id|
      next if role_id==1
      puts "role #{role_id} ok"
      raise "role #{role_id} not found" if !Role.exists?(role_id)
    end
    user=User.create(:email => email, :password => pwd, :password_confirmation => pwd)
    puts email
    puts pwd
    sql = []
    sql << "BEGIN;"
    roles_array.each do |role_id|
      sql << %Q{insert into roles_users (role_id , user_id) values (#{role_id},#{user.id});}
    end
    sql << "UPDATE users SET email = '#{cl.username}' WHERE id=#{user.id};"
    sql << "COMMIT;"
    sql = sql.join("\n");
    puts sql
    User.connection.execute(sql)
    puts "password per utente #{cl.username} con id #{user.id} : #{pwd}"
    return true
  end

  def User.googledrive_session
    config = Rails.configuration.database_configuration
    username=config[Rails.env]["google_drive_login"]
    passwd=config[Rails.env]["google_drive_passwd"]
    GoogleDrive.login(username, passwd)
  end

  def User.sp_user_select
    sql=%Q{select u.id as key,cl.lastname || ' ' || cl.name as label from public.users u join clavis.librarian cl on(cl.username=u.email) left join public.roles_users ru on (ru.user_id=u.id and ru.role_id=43) where ru is null order by cl.lastname}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

end
