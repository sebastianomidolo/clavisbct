# coding: utf-8

class SbctSuppliersController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="PAC - Fornitori"
    @supplier = SbctSupplier.new(params[:sbct_supplier])
    if !params[:supplier_insert_from_clavis].blank? and params[:supplier_insert_from_clavis].size >= 3
      @supplier.supplier_name=params[:supplier_insert_from_clavis]
      SbctSupplier.insert_from_clavis(@supplier.supplier_name)
    end
    if !params[:update_from_clavis].blank?
      SbctSupplier.insert_dl_from_clavis
    end
    @sbct_suppliers = SbctSupplier.tutti(params)
  end

  def clavisbct_access
    @sbct_supplier = SbctSupplier.find(params[:id])
    username = @sbct_supplier.clavisbct_username
    if request.request_method=='POST'
      sql = "INSERT into public.users (email) values('#{username}') on conflict(email) do nothing;"
      SbctUser.connection.execute(sql)
      user = User.find_by_email(username)
      if !user.role?('AcquisitionSupplier')
        user.roles << Role.find_by_name('AcquisitionSupplier')
      end
      p1=(0...2).map { (97 + rand(26)).chr }.join
      p2=(0...4).map { (49 + rand(9)).chr }.join
      passwd = p1+p2
      user.password=passwd
      user.save
      @sbct_supplier.external_user_id=user.id
      flash[:notice] = passwd
    end
    if request.request_method=='DELETE'
      user = User.find_by_email(username)
      user.roles = []
      @sbct_supplier.external_user_id=nil
    end
    @sbct_supplier.save
    redirect_to @sbct_supplier
  end

  def show
    @sbct_supplier=SbctSupplier.find(params[:id])
    @pagetitle=@sbct_supplier.to_label
  end

  def new
    @pagetitle="PAC-IS"
    @sbct_supplier = SbctSupplier.new
    respond_with(@sbct_supplier)
  end

  def create
    @sbct_supplier = SbctSupplier.new(params[:sbct_supplier])
    @sbct_supplier.save
    respond_with(@sbct_supplier)
  end
  
  def edit
  end

  def invoices
  end

  def orders_report
    @sbct_order = SbctOrder.new(supplier_id:@sbct_supplier.id)
    params[:supplier_id]=@sbct_supplier.id
    @sbct_items=SbctItem.order_items(@sbct_order,params)
    respond_to do |format|
      format.html {}
      format.csv {
        require 'csv'
        if @sbct_supplier.discount == 0.0
          csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
            csv << ['EAN','Autore','Titolo','Editore','Copie','Prezzo','Totale','Biblioteche','Note']
            @sbct_items.each do |r|
              csv << [r.ean,r.autore,r.titolo,r.editore,r.numcopie,r.prezzo_scontato,sprintf('%.02f', (r.prezzo_scontato.to_f*r.numcopie)),r.siglebct,r.note_fornitore]
            end
          end
        else
          csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
            csv << ['EAN','Autore','Titolo','Editore','Copie','Prezzo di listino','Prezzo scontato','Totale','Biblioteche','Note']
            @sbct_items.each do |r|
              csv << [r.ean,r.autore,r.titolo,r.editore,r.numcopie,r.listino,r.prezzo_scontato,sprintf('%.02f', (r.prezzo_scontato.to_f*r.numcopie)),r.siglebct,r.note_fornitore]
            end
          end
        end
        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=#{@sbct_supplier.to_label}.csv"
      }
    end
  end

  def update
    if @sbct_supplier.update_attributes(params[:sbct_supplier])
      @sbct_supplier.save
      flash[:notice] = "Modifiche salvate"
      respond_with(@sbct_supplier)
    else
      render :action => "edit"
    end
  end

end
