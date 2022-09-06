# coding: utf-8

class SbctSuppliersController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @pagetitle="CR - Fornitori"
    @sbct_suppliers = SbctSupplier.tutti(params)
  end

  def show
    @sbct_supplier=SbctSupplier.find(params[:id])
    @pagetitle=@sbct_supplier.to_label
  end

end
