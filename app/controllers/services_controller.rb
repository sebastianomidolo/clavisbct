# coding: utf-8
class ServicesController < ApplicationController
  before_filter :authenticate_user!
  # before_filter :authenticate_user!, except: [:index, :show]
  layout 'csir'
  load_and_authorize_resource only: [:edit, :show, :update, :destroy, :roles, :d_objects, :add_d_object]
  respond_to :html

  def index
    @services = Service.where('parent_id is null')
  end

  def new
    @service = Service.new
    if params[:parent_id].to_i > 0
      @service.parent_id = params[:parent_id].to_i
      @lock_parent = true
    end
  end

  def d_objects
    # dopf sta per "digital objects personal folder"
    @dopf = DObjectsPersonalFolder.find(user_session[:d_objects_personal_folder]) if !user_session[:d_objects_personal_folder].nil?
  end
  def add_d_object
    @dopf = DObjectsPersonalFolder.find(user_session[:d_objects_personal_folder]) if !user_session[:d_objects_personal_folder].nil?
    raise 'no no!' if @dopf.nil?
    d_object_id = params[:d_object_id].to_i
    if @dopf.ids.include?(d_object_id)
    else
      raise "parametro #{d_object_id} errato"
    end
    a=Attachment.new
    a.attachable_type='Service'
    a.attachable_id=@service.id
    a.d_object_id=d_object_id
    # render text:a.attributes
    a.save!
    # @service.attachments << a
    redirect_to d_objects_service_path
  end

  def create
    @service = Service.new(params[:service])
    @service.save
    respond_with(@service)
  end

  def show
    @service_docs = @service.service_docs
    @service_doc = ServiceDoc.new(params[:service_doc])
    @service_doc.service = @service
    @service_docs = ServiceDoc.tutti(@service_doc,current_user)
  end

  def edit
    @service = Service.find(params[:id])
  end

  def roles
  end

  def update
    @service.update_attributes(params[:service])
    respond_with(@service)
  end

  def destroy
    @parent = @service.parent if !@service.parent.nil?
    @service.destroy
    if @parent.nil?
      redirect_to services_path
    else
      redirect_to service_path(@parent)
    end
  end
  
end
