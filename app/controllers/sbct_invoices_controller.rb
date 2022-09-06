# coding: utf-8

class SbctInvoicesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @pagetitle="CR - Fatture"
    @sbct_invoices = SbctInvoice.tutte(params)
  end

  def show
    @sbct_invoice=SbctInvoice.find(params[:id])
    @pagetitle=@sbct_invoice.to_label
    if params[:ddt_numero].blank?
      @sbct_invoice_items = @sbct_invoice.sbct_invoice_items
    else
      @sbct_invoice_items = @sbct_invoice.sbct_invoice_items.where(ddt_numero:params[:ddt_numero])
    end
  end

end
