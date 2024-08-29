# coding: utf-8
class SerialInvoicesController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_list, only:[:index,:new,:create]
  before_filter :set_serial_invoice, only:[:edit,:show,:update]
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="Fatture #{@serial_list.to_label}"
  end

  def show
    params[:serial_list_id]=@serial_list.id
  end

  def edit
    flag = params[:invoice_filter_enabled]=='true' ? true : false
    params[:invoice_id]=@serial_invoice.id if params[:invoice_id].blank?
    params[:library_id]=@serial_list.serial_libraries.first.clavis_library_id if params[:library_id].blank?
    @serial_titles=SerialTitle.trova(params,flag)
  end
  
  def new
    @serial_invoice = SerialInvoice.new
    @serial_invoice.serial_list_id=@serial_list.id
    @pagetitle="#{@serial_list.to_label} - inserimento fattura"
    respond_with(@serial_invoice)
  end

  def create
    @serial_invoice=SerialInvoice.new(params[:serial_invoice])
    @serial_invoice.serial_list_id=@serial_list.id
    @serial_invoice.save
    respond_with(@serial_invoice)
  end

  def update
    titles=params[:titles]
    if titles.nil?
      @serial_invoice.update_attributes(params[:serial_invoice])
      respond_with(@serial_invoice)
    else
      titles_invoice=params[:titles_invoice]
      titles_ids = titles.nil? ? [] : titles.keys
      titles_invoice_ids = titles_invoice.nil? ? [] : titles_invoice.keys
      t=@serial_invoice.set_titles(titles_ids,titles_invoice_ids,params[:library_id])
      redirect_to serial_titles_path(library_id:params[:library_id],serial_list_id:params[:serial_list_id],invoice_id:@serial_invoice.id)
    end
  end
  
  private
  def set_serial_list
    @serial_list=SerialList.find(params[:serial_list_id])
  end
  def set_serial_invoice
    @serial_invoice=SerialInvoice.find(params[:id])
    @serial_list=@serial_invoice.serial_list
    @pagetitle="Fattura #{@serial_invoice.to_label}"
  end

end
