class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :registerable
  devise :database_authenticatable,:registerable,
         :recoverable, :rememberable, :trackable, :validatable
  attr_accessible :email, :password, :password_confirmation, :remember_me

  def User.googledrive_session
    config = Rails.configuration.database_configuration
    username=config[Rails.env]["google_drive_login"]
    passwd=config[Rails.env]["google_drive_passwd"]
    GoogleDrive.login(username, passwd)
  end
end
