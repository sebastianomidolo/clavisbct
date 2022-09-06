# coding: utf-8

class SbctBudgetsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="CR - Budgets"
    # SbctBudget.assegna_fornitori
    SbctBudget.allinea_prezzi_copie
    @sbct_budgets = SbctBudget.tutti(params)
  end

  def show
    @sbct_budget=SbctBudget.find(params[:id])
    @pagetitle=@sbct_budget.to_label
  end


  def update
    @sbct_budget = SbctBudget.find(params[:id])
    respond_to do |format|
      if @sbct_budget.update_attributes(params[:sbct_budget])
        # @sbct_budget.updated_by=current_user.id
        # @sbct_budget.budget_label = params[:budget_label]
        @sbct_budget.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_budget) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
end
