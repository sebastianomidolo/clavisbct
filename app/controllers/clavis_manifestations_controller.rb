class ClavisManifestationsController < ApplicationController
  include LatexPrint
  include REXML

  layout 'navbar'

  def index
  end

  def attachments_list
    headers['Access-Control-Allow-Origin'] = "*"
    ids=params[:m]
    res={}
    if !ids.blank?
      sql=%Q{select distinct attachable_id as manifestation_id,attachment_category_id as category from attachments where attachable_type='ClavisManifestation' and attachable_id in(#{ids.split.join(',')})}
      pg=ActiveRecord::Base.connection.execute(sql)
      pg.each do |r|
        res[r['manifestation_id']]=r['category'].blank? ? 'C' : r['category']
      end
    end
    respond_to do |format|
      format.json { render :json => res }
    end
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
    # order = bs=='SBN' ? '' : 'bib_level,created_by'
    order = 'bib_type,created_by'
    order += ",manifestation_id" if !order.blank?
    if params[:digit].blank?

      polo=params[:polo]
      if !polo.blank?
        condtext=[]
        cond.delete(:bib_level)
        cond.each_pair do |k,v|
          condtext << "#{k}=#{ActiveRecord::Base::connection.quote(v)}"
        end
        polo=ActiveRecord::Base::connection.quote("^#{polo}")
        condtext << "bid ~* #{polo}" 
        cond=condtext.join(" AND ")
        logger.info(cond)
        order = "modified_by, bid"
      end
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
    redirect_to cm.clavis_url and return if !params[:redir].blank?
    respond_to do |format|
      format.html
      format.xml {
        render xml: cm.export_to_metaopac
      }
    end
  end

  def attachments
    headers['Access-Control-Allow-Origin'] = "*"

    @dng_session=DngSession.find_by_params_and_request(params,request)

    @clavis_manifestation=ClavisManifestation.find(params[:id])
    respond_to do |format|
      format.html
      format.js
      format.pdf {
        filenum=params[:filenum].blank? ? 0 : params[:filenum].to_i
        fname=@clavis_manifestation.attachments_generate_pdf(true)[filenum]
        key=Digest::MD5.hexdigest(fname)
        if key!=params[:fkey]
          render :text=>"error #{fname}", :content_type=>'text/plain'
          return
        end
        ac=DngSession.access_control_key(params,request)
        if ac.nil? or ac!=params[:ac]
          render :text=>"Error! (wrong dng_user or dng_session expired)",:content_type=>'text/plain' and return
        end
        pdfdata=File.read(fname)
        send_data(pdfdata,
                  :filename=>File.basename(fname),:disposition=>'inline',
                  :type=>'application/pdf')
      }
    end
  end

  def sbn_opac_redir
    cm=ClavisManifestation.find_by_bid(params[:id])
    if cm.nil?
      render :text=>"BID #{params[:id]} non trovato"
    else
      redirect_to cm.clavis_url(:opac)
    end
  end

  def libriparlati_con_audio
    @records=Attachment.libriparlati(params[:colloc])
    respond_to do |format|
      format.html
      format.csv  {
        require 'csv'
        csv_string = CSV.generate do |csv|
          csv << ["Collocazione", "Titolo"]
          @records.each do |r|
            csv << [r['collocation'],r['title']]
          end
        end
        send_data csv_string, type: Mime::CSV,
        disposition: "attachment; filename=libriparlati_con_audio.csv"
      }
    end
  end

  def periodici_ordini
    parm={}
    parm[:numero_fattura]=params[:numero_fattura] if !params[:numero_fattura].blank?
    per_page=250
    if params[:library_id].blank? or params[:year].blank?
    else
      ordine=Ordine.new(library_id: params[:library_id], ordanno: params[:year])
      @records=ClavisManifestation.periodici_ordini(ordine,params[:page],per_page,parm)
    end
  end

end
