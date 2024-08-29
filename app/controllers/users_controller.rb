# coding: utf-8
class UsersController < ApplicationController
  before_filter :authenticate_user!
  # layout 'sbct'
  layout 'csir'
  load_and_authorize_resource
  respond_to :html

  def index
    # render text:request.params and return
    if params[:direction].blank?
      params[:direction] = 'asc'
    else
      params[:direction] = params[:direction]=='asc' ? 'desc' : 'asc'
    end
    @users=User.tutti(params)
  end

  def new
  end

  def create
    @user = User.new(params[:user])
    # scavalco la validazione indirizzo email, visto che qui email vale come login e può anche non essere un vero indirizzo email
    sql="INSERT INTO public.users (email) values(#{@user.connection.quote(@user.email)})"
    @user.connection.execute(sql)
    # @user.save
    respond_with(@user)
  end

  def update
    if @user.update_attributes(params[:user])
      @user.save
      flash[:notice] = "Modifiche salvate"
      respond_with(@user)
    else
      render :action => "edit"
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path(order:'email')
  end

end


