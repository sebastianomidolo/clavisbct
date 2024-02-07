# coding: utf-8

class SbctLBudgetLibrariesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    if params[:budget_id]
      @sbct_budget=SbctBudget.find(params[:budget_id])
      @sbct_l_budget_libraries = @sbct_budget.pac_libraries
    end
    # render text:@sbct_l_budget_libraries.size
  end

  def add_library
    @sbct_budget=SbctBudget.find(params[:budget_id])
    SbctLBudgetLibrary.create(budget_id:@sbct_budget.id,clavis_library_id:params[:clavis_library_id].to_i)
    redirect_to sbct_l_budget_libraries_path(budget_id:@sbct_budget.id)
  end

  def edit
    @sbct_budget = @sbct_l_budget_library.sbct_budget
    render text:'budget non modificabile (chiuso)', layout:true and return if @sbct_budget.locked?
  end

#  def create
#    l = SbctLBudgetLibrary.new(params[:sbct_l_budget_library])
#    l.save
#    redirect_to sbct_budget_path(l.sbct_budget)
#  end

  def update
    quota = params[:sbct_l_budget_library]
    quota = quota['quota'].gsub(',','.')
    n,d = quota.split('/').map {|x| x.to_f}
    if d.nil?
      quota = n
    else
      quota = (n/d).round(2)
    end
    subquota = params[:sbct_l_budget_library]['subquota'].to_f
    # render text:quota and return
    @sbct_l_budget_library.quota=quota
    @sbct_l_budget_library.subquota=subquota
    @sbct_l_budget_library.save
    redirect_to sbct_l_budget_libraries_path(budget_id:@sbct_l_budget_library.budget_id)
  end

  def destroy
    l = SbctLBudgetLibrary.find(params[:id])
    budget=l.sbct_budget
    l.destroy
    redirect_to sbct_l_budget_libraries_path(budget_id:budget.id)
  end

end
