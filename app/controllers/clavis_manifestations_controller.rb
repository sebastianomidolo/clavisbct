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
    order = bs=='SBN' ? '' : 'bib_level,created_by'
    order += ",manifestation_id" if !order.blank?
    if params[:digit].blank?
      @clavis_manifestations=ClavisManifestation.paginate(:conditions=>cond,
                                                          :page=>params[:page],
                                                          :order=>order)
    else
      @clavis_manifestations=ClavisManifestation.paginate_by_sql('select * from clavis.digitalizzati order by lower(title)', :page=>params[:page])
    end
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
    @clavis_manifestation=cm
    redirect_to cm.clavis_url if !params[:redir].blank?
  end

  def attachments
    headers['Access-Control-Allow-Origin'] = "*"

    @clavis_manifestation=ClavisManifestation.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end
end
