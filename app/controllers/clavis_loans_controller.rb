# coding: utf-8
# lastmod 21 febbraio 2013

class ClavisLoansController < ApplicationController
  layout 'navbar'
  load_and_authorize_resource only: [:index, :view_goethe_loans_xxx]

  def index
  end


  # Esempio parametri:
  #     date_from=01-03-2016&date_to=31-03-2016&per_page=200&order=ci.title
  #     date_from=01-01-2015&date_to=31-12-2015&per_page=100&order=p.loan_date_begin+desc
  # Si può avere anche un parametro "view":
  #     view=by_month (in questo caso il parametro "per_page" viene ignorato)
  def view_goethe_loans
    ActiveRecord::Base.connection.execute("SET DateStyle TO ISO, DMY;")
    @clavis_loans=ClavisLoan.loans_by_supplier(269, params)
  end

  def receipts
    ActiveRecord::Base.connection.execute("SET DateStyle TO ISO, DMY; SET timezone TO 'GMT-1';")
    ldb=params[:loan_date_begin]
    params[:loan_date_begin]=Time.now.to_date - 1.day if ldb.blank?
    params[:library_id]=2 if params[:library_id].blank?
    @clavis_loans=ClavisLoan.receipts(params)
    respond_to do |format|
      format.html { }
      format.pdf  {
        filename="#{@clavis_loans.size} ricevute.pdf"
        pdf=ClavisLoan.receipts_pdf(@clavis_loans)
        send_data(pdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
    end
  end

end
