class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  attr_accessible :email, :password, :password_confirmation, :remember_me

  def google_doc_key
    h={
      civ:    '1dKUg08NvSWQmOy0oJ6lKsagHFIDi4bbkeqKbJgsBf9k',
      copat1: '1aSJzKCI1_WlimHWtbgd5LircGAkEOrpCK90sH0n9ySs',
      copat2: '1150XuZU2DcxiYc7URUKMYpgoVwmRMcpahSr1dAAmvMY',
      copat3: '1XuRHleKDxgo_LtO4kGxaWEpxuNMxwIqN_7-gPuM9v9o',
    }
    h[self.email.to_sym]
  end
end
