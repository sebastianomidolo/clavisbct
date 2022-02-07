class ApplicationController < ActionController::Base
  before_filter :store_user_location!, if: :storable_location?
  protect_from_forgery
  layout 'navbar'
  rescue_from CanCan::AccessDenied do |exception|
    render file: "#{Rails.root}/public/403", formats: [:html], status: 403, layout: true
  end

  private
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def filter_current_params(params)
    prm={}
    params.keys.each do |p|
      next if ['id','utf8','action','controller','au'].include?(p)
      prm[p]=params[p]
    end
    prm
  end

end
