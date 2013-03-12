class ClavisManifestationsController < ApplicationController
  include LatexPrint

  def index
  end

  def shortlist
    bs=params[:bid_source]
    cond={:bid_sourcex=>bs}
    # @clavis_manifestations=ClavisManifestation.find(:all, :limit=>10, :conditions=>cond)
  end

  def kardex
    @clavis_manifestation=ClavisManifestation.find(params[:id])
  end
  def testpdf
    respond_to do |format|
      format.html {
        render :text=>'pdf'
      }
      format.pdf  {
        lp=LatexPrint::PDF.new('sample')
        texdata=lp.read_template
        pdf=lp.make_pdf(texdata)
        send_data(pdf,
                  :filename=>"test.pdf",:disposition=>'inline',
                  :type=>'application/pdf')
      }
    end
  end
end
