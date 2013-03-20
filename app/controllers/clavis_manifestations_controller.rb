class ClavisManifestationsController < ApplicationController
  include LatexPrint

  def index
  end

  def shortlist
    cond={:bib_level=>['m','c','s']}
    bs=params[:bid_source]
    if bs=='null'
      cond[:bid_source]=nil
    else
      cond[:bid_source]=bs if !bs.blank?
    end
    bl=params[:bib_level]
    cond[:bib_level]=bl if !bl.blank?
    bt=params[:bib_type]
    cond[:bib_type]=bt if !bt.blank?
    # @clavis_manifestations=ClavisManifestation.find(:all, :limit=>300, :conditions=>cond)
    # @clavis_manifestations=ClavisManifestation.where(cond).paginate(:page=>params[:page])
    order = bs=='SBN' ? '' : 'bib_level'
    order += ",manifestation_id" if !order.blank?
    @clavis_manifestations=ClavisManifestation.paginate(:conditions=>cond,
                                                        :page=>params[:page],
                                                        :order=>order)
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
