class HomeController < ApplicationController
  # before_filter :authenticate_user!
  def index
    @msg=Time.now
    # authenticate_user!
  end

  def spazioragazzi
    render :text=>File.read('/tmp/indexfile.html')
  end
end

