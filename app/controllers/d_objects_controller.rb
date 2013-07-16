require 'RMagick'

class DObjectsController < ApplicationController

  def index
    cond=[]
    cond << "mime_type='#{params[:mime_type]}'" if !params[:mime_type].blank?
    cond << "filename ~* #{ActiveRecord::Base.connection.quote(params[:filename])}" if !params[:filename].blank?
    cond << "tags::text ~* #{ActiveRecord::Base.connection.quote(params[:tags])}" if !params[:tags].blank?
    cond = cond.join(" AND ")
    cond = "false" if cond.blank?
    order='filename'
    @d_objects = DObject.paginate(:conditions=>cond,
                                  :page=>params[:page],
                                  :order=>order)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @d_objects }
    end
  end

  def objshow
    @d_object = DObject.find(params[:id])
    key=Digest::MD5.hexdigest(@d_object.filename)
    # test="id: #{@d_object.id} - filename: #{@d_object.filename} - #{key} <=> #{params[:key]}"
    if key!=params[:key] and request.remote_ip!='158.102.56.204'
      render :text=>"error #{request.remote_ip}", :content_type=>'text/plain'
      return
    end
    log="#{Time.new}|objshow|#{@d_object.id}|#{request.remote_ip}|dng_user=#{params[:dng_user]}"
    logger.warn(log)
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @d_object }
      format.pdf {
        send_file(@d_object.filename_with_path,
                  :type=>@d_object.mime_type)
      }
      format.jpeg {
        logo = Magick::Image.read("/home/storage/preesistente/testzone/logo.jpg").first
        if !@d_object.get_pdfimage.nil?
          img=Magick::Image.read(@d_object.get_pdfimage).first
        else
          img=Magick::Image.read(@d_object.filename_with_path).first
          img.format='jpeg'
        end
        # img.scale!(0.25)
        # img.resize_to_fit!(300, 300)
        img.resize_to_fit!(800, 800)
        # http://www.imagemagick.org/RMagick/doc/image3.html#watermark
        img=img.watermark(logo,0.1,0.5,Magick::NorthGravity,0,0)
        img=img.watermark(logo,0.1,0.5,Magick::SouthGravity,0,0)
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
        # send_file(@d_object.get_pdfimage, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
      }
      format.mp3 {
        send_file(@d_object.filename_with_path, :type => 'audio/mpeg; charset=binary', :disposition => 'inline')
      }

    end
  end

  def showfile
    # Controlli sull'autorizzazione da inserire qui
    @d_object = DObject.find(params[:id])
    # render :text=>'@d_object.filename'
    respond_to do |format|
      format.txt 
      format.json { render json: @d_object }
    end

    render :text=>@d_object.mime_type
  end

end
