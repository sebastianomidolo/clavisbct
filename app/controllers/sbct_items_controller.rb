# coding: utf-8
class SbctItemsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource except: [:assign_to_other_supplier]

  respond_to :html

  def index
    @pagetitle="PAC - Copie"
    if params[:sbct_item].blank?
      @sbct_item = SbctItem.new()
    else
      @sbct_item = SbctItem.new(params[:sbct_item])
    end

    @sql = SbctItem.sql_for_tutti(@sbct_item, params)
    @sbct_items = SbctItem.tutti(@sbct_item, params)

    user_session[:sbct_titles_ids]=@sbct_items.collect {|i| i.id_titolo}
    user_session[:sbct_titles_ids] = user_session[:sbct_titles_ids].uniq

    
    @prezzo_totale = SbctItem.somma_prezzo(@sbct_items)
    # render text:@sbct_items.inspect and return
  end

  def togli_da_ordine
    @sbct_item.togli_da_ordine
    redirect_to sbct_title_path(@sbct_item.sbct_title)
  end

  def aggiungi_a_ordine
    @sbct_item.aggiungi_a_ordine(SbctOrder.find(params[:order_id]))
    redirect_to sbct_title_path(@sbct_item.sbct_title)
  end

  def supplier_unassign
    @sbct_item.supplier_unassign
    redirect_to sbct_title_path(@sbct_item.sbct_title)
  end

  def show
    @pagetitle="PID-C-#{@sbct_item.id}"
    @sbct_title = @sbct_item.sbct_title
    @esemplari_presenti_in_clavis = @sbct_title.esemplari_presenti_in_clavis
  end

  def edit
    if !@sbct_item.editable?(current_user)
      render text:'non accessibile in modifica', layout:true
      return
    end
    @pagetitle="PID-MC-#{@sbct_item.id}"
    params[:library_id]=@sbct_item.library_id
    @sbct_order = @sbct_item.sbct_order
    @current_order = SbctOrder.find(user_session[:current_order]) if !user_session[:current_order].nil?  

    if current_user.role?('AcquisitionLibrarian')
      @sbct_suppliers=@sbct_item.sbct_budget.sbct_suppliers
      # @sbct_suppliers = SbctSupplier.available_suppliers_2(@sbct_item)
      # render text:'dbg' and return
      render 'assign_to_other_supplier'
    end
  end

  def new
    @pagetitle="PID-IC-#{params[:id_titolo].to_i}"
    @current_order = SbctOrder.find(user_session[:current_order]) if !user_session[:current_order].nil?  
    @current_budget = SbctBudget.find(user_session[:current_budget]) if !user_session[:current_budget].nil?

    @sbct_item = SbctItem.new(id_titolo:params[:id_titolo].to_i)
    respond_with(@sbct_item)
  end

  def add
    item = SbctItem.new(params[:sbct_item])
    title_ids=params[:title_ids].collect {|x| x.to_i}
    sql=item.batch_insert_sql(title_ids,current_user)
    budget_id = item.budget_id==0 ? '' : item.budget_id
    item.connection.execute(sql)
    # render text:"<pre>#{sql}</pre>", layout:true and return
    redirect_to "/sbct_items?sbct_item[library_id]=#{item.library_id}&sbct_item[budget_id]=#{budget_id}&sbct_item[order_status]=S"
  end

  def create
    #if params[:sbct_item][:id_titolo].to_i == 411189
    params[:sbct_item]['user_id']=current_user.id
    # render text:params[:sbct_item][:id_titolo] and return
    # render text:params[:sbct_item].inspect and return
    SbctItem.multi_items_insert(params[:sbct_item])
    @sbct_title = SbctTitle.find(params[:sbct_item][:id_titolo])
    #else
    #  @sbct_item = SbctItem.new(params[:sbct_item])
    #  @sbct_item.created_by = current_user.id
    #  @sbct_item.save
    #  # respond_with(@sbct_item)
    #  @sbct_title = @sbct_item.sbct_title
    #end
    # respond_with(@sbct_title)
    redirect_to sbct_title_path(@sbct_title, norecurs:true)
  end

  def destroy
    @sbct_title = @sbct_item.sbct_title
    @sbct_item.save_before_delete(current_user.id)
    @sbct_item.destroy
    respond_with(@sbct_title)
  end

  def selection_confirm
    @sbct_title = @sbct_item.sbct_title
    @sbct_item.strongness=1
    @sbct_item.confirmed_by = current_user.id
    @sbct_item.qb = true
    @sbct_item.current_user = current_user
    @sbct_item.save
    respond_with(@sbct_title)    
  end

  def update
    @sbct_item = SbctItem.find(params[:id])
    @sbct_item.current_user = current_user
    respond_to do |format|
      if @sbct_item.update_attributes(params[:sbct_item])
        @sbct_item.date_created = Time.now if @sbct_item.date_created.nil?
        @sbct_item.updated_by=current_user.id
        @sbct_item.date_updated = Time.now
        @sbct_item.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_item.sbct_title) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def assign_to_other_supplier
    @sbct_item = SbctItem.find(params[:id])
    if !@sbct_item.editable?(current_user)
      render text:'non accessibile in modifica', layout:true
      return
    end

    @sbct_item=SbctItem.find(params[:id])
    if !params[:target_supplier].blank?
      @sbct_item.assign_to_other_supplier(SbctSupplier.find(params[:target_supplier]))
      redirect_to sbct_title_path(@sbct_item.id_titolo)
    end
    # @sbct_suppliers = SbctSupplier.available_suppliers('^MiC22', '^MiC 2022', @sbct_item)
    @sbct_suppliers = SbctSupplier.available_suppliers_2(@sbct_item)
    # render text:@sbct_suppliers and return
    # @sbct_suppliers=@sbct_item.sbct_budget.sbct_suppliers
  end

  def assign_to_other_title
    @sbct_item=SbctItem.find(params[:id])
  end

  def assign_to_library
    @sbct_item.home_library_id=params[:library_id]
    @sbct_item.save if @sbct_item.changed?
  end

  def change_item_order_status
    @sbct_item=SbctItem.find(params[:id])
    respond_to do |format|
      format.html {
      }
      format.js {
        # @sdeng = "ooooohhh!"
        if !params[:order_status].blank?
          @sbct_item.order_status=params[:order_status]
          @sbct_item.order_status_updated_by = current_user.id
          @sbct_item.current_user = current_user
          @sbct_item.save
        end
      }
    end
  end

  
end
