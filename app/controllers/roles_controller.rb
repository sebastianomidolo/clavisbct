class RolesController < ApplicationController
  before_filter :authenticate_user!
  layout 'csir'
  load_and_authorize_resource
  respond_to :html

  def index
    @roles=Role.find_by_sql("select r.name,r.id,array_to_string(array_agg(u.email order by email),', ') as usernames, count(*) from roles r join roles_users ru on(ru.role_id=r.id) join users u on(u.id=ru.user_id) group by r.id order by r.name;")
  end

end


