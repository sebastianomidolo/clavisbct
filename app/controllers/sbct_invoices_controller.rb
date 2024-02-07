# coding: utf-8

class SbctInvoicesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index

    if current_user.role?("AcquisitionSupplier") == false
      @pagetitle="PAC - Fatture"
      @sbct_invoices = SbctInvoice.tutte(params)
      if !params[:supplier_id].blank?
        @sbct_supplier = SbctSupplier.find(params[:supplier_id])
      end
      # SbctInvoice.roundings('^MiC',difetto=true)
    else
      if params[:supplier_id].blank?
        @sbct_supplier = current_user.sbct_supplier
        params[:supplier_id]=@sbct_supplier.id
      else
        @sbct_supplier = SbctSupplier.find(params[:supplier_id])
      end
      if params[:supplier_id].to_i != current_user.sbct_supplier.id
        render text:"non accessibile", layout:true
        return
      end
      @sbct_invoices = SbctInvoice.tutte(params)
    end

    if !params[:invoices_create].blank?
      sql = @sbct_supplier.auto_create_invoices
      # render text:"<pre>#{sql}</pre>" and return
      redirect_to sbct_invoices_path(supplier_id:@sbct_supplier.id)
    end

    respond_to do |format|
      format.html {}
      format.csv {
        require 'csv'

        cond = params[:library_id].nil? ? '' : "AND cp.library_id=#{SbctItem.connection.quote(params[:library_id])}"
        items = SbctItem.find_by_sql("select t.ean,t.autore,t.titolo,t.editore,lc.label as siglabib,cp.numcopie,cp.prezzo from sbct_acquisti.titoli t join sbct_acquisti.copie cp using(id_titolo) join sbct_acquisti.invoices i using(invoice_id) join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cp.library_id) where cp.supplier_id=#{@sbct_supplier.id} #{cond} order by lc.label,t.titolo")
        csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
          csv << ['EAN','Autore','Titolo','Editore','Copie','Prezzo','Totale','Biblioteche']
          items.each do |r|
            csv << [r.ean,r.autore,r.titolo,r.editore,r.numcopie,r.prezzo,sprintf('%.02f', (r.prezzo.to_f*r.numcopie)),r.siglabib]
          end
        end
        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=#{@sbct_supplier.to_label}.csv"
      }
    end

  end

  def edit
  end

  def update
    if @sbct_invoice.update_attributes(params[:sbct_invoice])
      @sbct_invoice.save
      flash[:notice] = "Modifiche salvate"
      respond_with(@sbct_invoice)
    else
      render :action => "edit"
    end
  end

  def show
    @sbct_invoice=SbctInvoice.find(params[:id])
    @sbct_supplier = @sbct_invoice.sbct_supplier
    if !current_user.roles.where("name='AcquisitionSupplier'").first.nil?
      if current_user.sbct_supplier != @sbct_supplier
        render text:'no way...', layout:true
      end
    end
    @pagetitle=@sbct_invoice.to_label
    @sbct_order = SbctOrder.new(supplier_id:@sbct_supplier.id)
    params[:supplier_id]=@sbct_supplier.id
    params[:invoice_id]=@sbct_invoice.id
    params[:group_by]='title'
    @sbct_items=SbctItem.order_items(@sbct_order,params)
  end

end
