class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :registerable

  devise :database_authenticatable,:registerable, :recoverable, :rememberable, :trackable, :validatable
  # devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me

  def containers_enabled?
    config = Rails.configuration.database_configuration
    config[Rails.env]["container_users"].include?(self.id)
  end

  def User.googledrive_session
    config = Rails.configuration.database_configuration
    username=config[Rails.env]["google_drive_login"]
    passwd=config[Rails.env]["google_drive_passwd"]
    GoogleDrive.login(username, passwd)
  end
end
