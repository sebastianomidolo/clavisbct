class HomeController < ApplicationController
  # before_filter :authenticate_user!
  def index
    @msg=Time.now
    # authenticate_user!
  end

  def jsonip
    headers['Access-Control-Allow-Origin'] = "*"
    headers['Access-Control-Allow-Methods'] = "GET"
    render json: {ip: DngSession.format_client_ip(request)}.to_json
  end

  def spazioragazzi
    render :text=>File.read('/tmp/indexfile.html')
  end
end

