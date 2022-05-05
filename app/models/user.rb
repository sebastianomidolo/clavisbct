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

  def clavis_librarian
    ClavisLibrarian.find_by_username(self.email)
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
