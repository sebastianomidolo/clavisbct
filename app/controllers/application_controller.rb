class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'navbar'
  rescue_from CanCan::AccessDenied do |exception|
    render file: "#{Rails.root}/public/403", formats: [:html], status: 403, layout: true
  end
end
