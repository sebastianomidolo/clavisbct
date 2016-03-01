class UsersController < ApplicationController
  before_filter :authenticate_user!
  layout 'navbar'
  load_and_authorize_resource

  def index
    @users=User.all(order:'id')
  end
end


