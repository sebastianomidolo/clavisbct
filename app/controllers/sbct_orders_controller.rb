# coding: utf-8

class SbctOrdersController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    if current_user.roles.where("name='AcquisitionSupplier'").first.nil?
      @pagetitle="PAC - Ordini"
      @sbct_orders = SbctOrder.tutti(params)
      @sbct_supplier = SbctSupplier.find(params[:supplier_id]) if !params[:supplier_id].blank?
    else
      @sbct_supplier = current_user.sbct_supplier
      @pagetitle="PAC - Ordini #{@sbct_supplier.to_label}"
      params[:supplier_id] = @sbct_supplier.id
      params[:inviato] = true
      @sbct_orders = SbctOrder.tutti(params)
      render template:'sbct_invoices/prospetto_fatture'
    end
  end

  def edit
  end

  def destroy
    user_session[:current_order]=nil
    @sbct_order.destroy
    redirect_to sbct_orders_path
  end

  def new
    @pagetitle="PAC-IO"
    @sbct_order = SbctOrder.new
    @sbct_order.supplier_id = params[:supplier_id]
    # render text:@sbct_order.attributes and return
    respond_with(@sbct_order)
  end

  def create
    @sbct_order = SbctOrder.new(params[:sbct_order])
    @sbct_order.created_by = current_user.id
    @sbct_order.save
    respond_with(@sbct_order)
  end
  
  def update
    @sbct_order = SbctOrder.find(params[:id])
    if @sbct_order.update_attributes(params[:sbct_order])
      @sbct_order.save
      flash[:notice] = "Modifiche salvate"
      respond_with(@sbct_order)
    else
      render :action => "edit"
    end
  end

  def show
    if SbctTitle.user_roles(current_user).include?('AcquisitionManager') and !@sbct_order.inviato?
      user_session[:current_order]=@sbct_order.id
      user_session[:current_budget] = @sbct_order.budget_id.nil? ? nil : @sbct_order.budget_id
    else
      user_session[:current_order]=nil
      user_session[:current_budget]=nil
    end

    user_session[:sbct_titles_ids]=nil

    @pagetitle=@sbct_order.label
    @sbct_item = SbctItem.new(supplier_id:@sbct_order.supplier_id, order_date:@sbct_order.order_date)
    @sql = SbctItem.sql_for_order_items(@sbct_order, params)
    @sbct_items = SbctItem.order_items(@sbct_order,params)
    @sbct_supplier = @sbct_order.sbct_supplier
    @prezzo_totale = SbctItem.somma_prezzo(@sbct_items).round(2)
    # render text:@sql and return
    respond_to do |format|
      format.html {}
      format.xls {
        data = SbctItem.create_order_file(@sbct_supplier, @sbct_items, :xls)
        # data = File.read "/home/seb/prova.xlsx"
        # send_file("/home/seb/prova.xlsx", filename:"prova.xls", type:'application/vnd.ms-excel', disposition:'inline')
        send_data data, type: Mime::XLS, disposition: "attachment; filename=#{@sbct_order.to_label}.xls"
      }
      format.csv {
        data = SbctItem.create_order_file(@sbct_supplier, @sbct_items, :csv)
        send_data data, type: Mime::CSV, disposition: "attachment; filename=#{@sbct_order.to_label}.csv"
      }
    end
  end

  def prepare
    @sbct_title = SbctTitle.new(params[:sbct_title])
    with_sql,@sbct_title,sbct_list,sbct_budgets,sbct_budget=SbctTitle.sql_for_tutti(params,current_user)
    @sql = @sbct_order.sql_for_order_prepare(with_sql,@sbct_title,params[:qb_select])
    # render text:"<pre>SQL:\n#{@sql}</pre>" and return
    @sbct_items = SbctItem.paginate_by_sql(@sql, per_page:20000, page:params[:page])
    # render text:@sbct_items.count and return
    @prezzo_totale = SbctItem.somma_prezzo(@sbct_items)
  end

  def vrfy
    render text:'disabilitato per ora - correggi a mano per favore', layout:true and return
    sql = @sbct_order.discount_check(:update)
    # SbctItem.connection.execute(sql)
    redirect_to sbct_order_path
  end

  def add_items_to_order
    @sbct_order.add_items_to_order(params[:item_ids])
    respond_with(@sbct_order)
  end

end

