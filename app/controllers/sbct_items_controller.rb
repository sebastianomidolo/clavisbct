class SbctItemsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="Modulo acquisti - copie"
    if params[:sbct_item].blank?
      @sbct_item = SbctItem.new()
    else
      @sbct_item = SbctItem.new(params[:sbct_item])
    end
    @sql = SbctItem.sql_for_tutti(@sbct_item, params)
    # render text:@sql and return
    @sbct_items = SbctItem.tutti(@sbct_item, params)
    # render text:@sbct_items.inspect and return
  end

  def show
    @sbct_title = @sbct_item.sbct_title
    @esemplari_presenti_in_clavis = @sbct_title.esemplari_presenti_in_clavis
  end

  def edit
  end

  def new
    @sbct_item = SbctItem.new(id_titolo:params[:id_titolo].to_i)
    respond_with(@sbct_item)
  end

  def create
    @sbct_item = SbctItem.new(params[:sbct_item])
    @sbct_item.created_by = current_user.id
    @sbct_item.save
    respond_with(@sbct_item)
  end

  def orders
    @pagetitle="CR - Ordini"
    @orders = SbctItem.orders_toc(params)
    if @orders.size == 1
      if params[:order_date]=='NULL'
        @sbct_item = SbctItem.new(supplier_id:params[:supplier_id])
      else
        @sbct_item = SbctItem.new(supplier_id:params[:supplier_id], order_date:params[:order_date])
      end
      @sql = SbctItem.sql_for_tutti(@sbct_item, params)
      @sbct_items = SbctItem.tutti(@sbct_item, params)
    end
    respond_to do |format|
      format.html {}
      format.csv {
        require 'csv'
        csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
          csv << ['EAN','Autore','Titolo','Editore','Copie','Prezzo','Totale','Biblioteche']
          @sbct_items.each do |r|
            csv << [r.ean,r.autore,r.titolo,r.editore,r.numcopie,r.prezzo,r.prezzo*r.numcopie,r.siglebct]
          end
        end
        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=text.csv"
      }
    end

  end

  def create_order
    SbctItem.create_order(params[:item_ids])
    l = SbctList.find(params[:id_lista]) if !params[:id_lista].blank?
    l.nil? ? (render text:'no list') : respond_with(l)
  end

  def update
    @sbct_item = SbctItem.find(params[:id])
    respond_to do |format|
      if @sbct_item.update_attributes(params[:sbct_item])
        @sbct_item.updated_by=current_user.id
        @sbct_item.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_item.sbct_title) }
      else
        format.html { render :action => "edit" }
      end
    end
  end


end
