# coding: utf-8
class ClinicActionsController < ApplicationController
  layout 'clinic'
  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
  end
  def edit
  end
  def show
  end
  def nuova
    ClinicAction.nuova
    redirect_to clinic_actions_path
  end
  def update
    @clinic_action.update_attributes(params[:clinic_action])
    respond_with(@clinic_action)
  end
  def destroy
    @clinic_action.destroy
    redirect_to clinic_actions_path
  end
end
