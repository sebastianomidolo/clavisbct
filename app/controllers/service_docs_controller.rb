# coding: utf-8
class ServiceDocsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_service, only: [:show, :edit, :destroy]
  layout 'csir'
  load_and_authorize_resource only: [:edit, :update, :destroy, :d_objects, :add_d_object]
  respond_to :html

  def index
    @service_doc = ServiceDoc.new(params[:service_doc])
    if !params[:service_id].blank?
      @service = Service.find(params[:service_id])
      @service_doc.service = @service
    else
      @service=@service_doc.service
    end
    @service_docs = ServiceDoc.tutti(@service_doc,current_user)
  end

  def new
    @service = Service.find(params[:service_id])
    @service_doc = ServiceDoc.new(service_id:@service.id)
  end

  def d_objects
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
    a.attachable_type='ServiceDoc'
    a.attachable_id=@service_doc.id
    a.d_object_id=d_object_id
    a.save!
    redirect_to d_objects_service_doc_path
  end

  def create
    @service_doc = ServiceDoc.new(params[:service_doc])
    @service_doc.save
    respond_with(@service_doc)
  end

  def show
  end

  def update
    @service_doc.update_attributes(params[:service_doc])
    respond_with(@service_doc)
  end

  def destroy
    @service_doc.destroy
    redirect_to service_docs_path(service_id:@service.id)
  end
  
  private
  def set_service
    @service_doc = ServiceDoc.find(params[:id])
    @service=@service_doc.service
  end

  
end
