# coding: utf-8

class BioIconograficoNamespacesController < ApplicationController
  layout 'bioico'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="Repertori BCT - Amministrazione"
    @bio_iconografico_namespaces = BioIconograficoNamespace.tutti(params, current_user)
  end

  def show
    @pagetitle="Repertori BCT - #{@bio_iconografico_namespace.title}"
  end
  def edit
  end
  def new
  end

  def info
  end

  def create
    r = BioIconograficoNamespace.new(params[:bio_iconografico_namespace])
    r.save
    respond_with(r)
  end

  def update
    if @bio_iconografico_namespace.update_attributes(params[:bio_iconografico_namespace])
      if @bio_iconografico_namespace.clavis_username.blank?
        @bio_iconografico_namespace.save
      else
        @bio_iconografico_namespace.add_user(@bio_iconografico_namespace.clavis_username)
      end
      flash[:notice] = "Modifiche salvate"
      respond_with(@bio_iconografico_namespace)
      # redirect_to bio_iconografico_namespaces_path
    else
      render :action => "edit"
    end
  end

  def destroy
    if !params[:user_id].nil?
      u=User.find(params[:user_id])
      flash[:notice] = "Eliminato utente #{u.id} - #{u.email}"
      @bio_iconografico_namespace.delete_user(u.id)
      respond_with(@bio_iconografico_namespace)
    else
      if @bio_iconografico_namespace.numfiles==0
        @bio_iconografico_namespace.destroy
        redirect_to bio_iconografico_namespaces_path
      else
        respond_with(@bio_iconografico_namespace)
      end
    end
  end

end
