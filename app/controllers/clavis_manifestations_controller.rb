class ClavisManifestationsController < ApplicationController
  include LatexPrint

  def index
  end

  def shortlist
    bs=params[:bid_source]
    cond={:bid_source=>bs, :bib_level=>['m','c','s']}
    # @clavis_manifestations=ClavisManifestation.find(:all, :limit=>300, :conditions=>cond)
    # @clavis_manifestations=ClavisManifestation.where(cond).paginate(:page=>params[:page])
    @clavis_manifestations=ClavisManifestation.paginate(:conditions=>cond,:page=>params[:page])
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

  def show
    cm=ClavisManifestation.find(params[:id])
    redirect_to cm.clavis_url
  end
end
