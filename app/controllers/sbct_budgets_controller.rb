# coding: utf-8

class SbctBudgetsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="PAC - Budgets"
    # SbctBudget.assegna_fornitori
    # SbctBudget.allinea_prezzi_copie
    user_session[:current_budget]=nil
    @sbct_budgets = SbctBudget.tutti(params,current_user)
    user_session[:sbct_budgets_ids]=@sbct_budgets.collect {|i| i.id}
  end

  def show
    @sbct_budget=SbctBudget.find(params[:id])
    if SbctTitle.libraries_select(current_user).size > 0
      if current_user.role?(['AcquisitionManager','AcquisitionStaffMember','AcquisitionLibrarian'])
        user_session[:current_budget]=@sbct_budget.id if @sbct_budget.locked==false
      end
    else
      user_session[:current_budget]=nil
    end
    @pagetitle=@sbct_budget.to_label
  end

  def create
    @sbct_budget = SbctBudget.new(params[:sbct_budget])
    b = @sbct_budget.clavis_budget
    @sbct_budget.label = "#{b.budget_title} #{b.clavis_library.shortlabel.strip}"
    @sbct_budget.total_amount = b.total_amount
    @sbct_budget.save
    respond_with(@sbct_budget)
  end

  def new
    params[:insert_new_budget]='true'
  end

  def destroy
    @sbct_budget = SbctBudget.find(params[:id])
    if can? :new, @sbct_budget, current_user
      SbctBudget.connection.execute("delete from sbct_acquisti.budgets where budget_id=#{@sbct_budget.id};select setval('sbct_acquisti.budgets_budget_id_seq', (SELECT MAX(budget_id) FROM sbct_acquisti.budgets)+1)");
      if SbctTitle.user_roles(current_user).include?('AcquisitionManager')
        user_session[:current_budget]=nil
      end
      redirect_to sbct_budgets_path
    else
      render text:'non autorizzato', layout:true and return
    end
  end

  def suppliers
  end

  # Vecchia procedura create d'urgenza per risolvere lo specifico problema MiC22 nella fase di adozione di PAC
  # Vedi invece la nuova: "suppliers"
  def suppliers_assign_old
    render text:"suppliers_assign: Disabilitato il 29 settembre 2022"
    return

    SbctBudget.azzera_fornitori_mic22
    # redirect_to sbct_suppliers_path and return

    SbctBudget.assegna_fornitori('desc',[],[479,483,485],"c.library_id=3")
    SbctBudget.loop_assegna_fornitori('asc',[],[479,483,485],"c.library_id=3")
    SbctBudget.assegna_fornitori('desc',[],[481,490,470,486,471],"t.reparto='RAGAZZI'")
    SbctBudget.loop_assegna_fornitori('asc',[],[481,490,470,486,471],"t.reparto='RAGAZZI'")
    SbctBudget.assegna_fornitori('desc',[],[467],"t.reparto='FUMETTI'")
    SbctBudget.loop_assegna_fornitori('asc',[],[467],"t.reparto='FUMETTI'")

    SbctBudget.assegna_fornitori('desc',[],[475,477],"t.sottoreparto='GUIDE, CARTE e ATLANTI'")
    SbctBudget.loop_assegna_fornitori('asc',[],[475,477],"t.sottoreparto='GUIDE, CARTE e ATLANTI'")

    SbctBudget.loop_assegna_fornitori

    SbctOrder.trasforma_copie_selezionate_in_ordini(supplier_name_regexp='^MiC22')

    redirect_to sbct_suppliers_path
  end

  def release
    if request.method == 'POST'
      @sbct_budget.release_budget
      render :action => "show"
    end
  end
  # Nuova procedura 2023
  def suppliers_assign
    if request.method == 'POST'
      @sbct_budgets = SbctBudget.find(params[:budget_ids].collect {|x| x.to_i})
      @sbct_budgets.each {|b| b.spendi}
      redirect_to sbct_budgets_path(supplier:'null')
    else
      @sbct_budget = SbctBudget.new
    end
  end

  def update
    @sbct_budget = SbctBudget.find(params[:id])
    b=SbctBudget.new(params[:sbct_budget])
    if !b.supplier_filter.blank?
      redirect_to suppliers_sbct_budget_path(@sbct_budget,supplier_filter:b.supplier_filter) and return
    end
    respond_to do |format|
      if @sbct_budget.update_attributes(params[:sbct_budget])
        # @sbct_budget.updated_by=current_user.id
        # @sbct_budget.budget_label = params[:budget_label]
        @sbct_budget.reparto=nil if @sbct_budget.reparto.blank?
        @sbct_budget.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_budget) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
end
