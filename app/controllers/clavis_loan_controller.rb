# lastmod 21 febbraio 2013

class ClavisLoanController < ApplicationController
  def receipts
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
