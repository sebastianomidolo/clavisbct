# coding: utf-8
class RequestsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_request, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @requests = Request.all
    respond_to do |format|
      format.html
      format.pdf {
        filename="prova.pdf"
        lp=LatexPrint::PDF.new('requests', @requests, false)
        send_data(lp.makepdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
      format.csv {
        render text:'csv'
      }
    end
  end

  def show
    respond_with(@request)
  end

  def new
    @request = Request.new(patron_id:params[:patron_id],library_id:params[:library_id])
    respond_with(@request)
  end

  def edit
  end

  def create
    @request = Request.new(params[:request])
    @request.created_by = current_user.id
    @request.request_date = Time.now
    @request.save
    respond_with(@request)
  end

  def update
    @request.update_attributes(params[:request])
    @request.updated_by = current_user.id
    @request.date_updated = Time.new
    @request.save
    respond_with(@request)
  end

  def destroy
    @request.destroy
    respond_with(@request)
  end

  private
    def set_request
      @request = Request.find(params[:id])
    end
end
