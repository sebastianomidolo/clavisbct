# lastmod 21 febbraio 2013

class ClavisLoanController < ApplicationController
  def receipts
    @clavis_loans=ClavisLoan.receipts(params)
    respond_to do |format|
      format.html {
        render :text=>"@clavis_loans: #{@clavis_loans.size}"
      }
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
