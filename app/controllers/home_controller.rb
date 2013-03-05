class HomeController < ApplicationController
  # before_filter :authenticate_user!
  def index
    @msg=Time.now
    # authenticate_user!
  end
end

