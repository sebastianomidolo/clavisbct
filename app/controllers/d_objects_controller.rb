require 'RMagick'

class DObjectsController < ApplicationController

  def index
    cond=[]
    cond << "mime_type='#{params[:mime_type]}'" if !params[:mime_type].blank?
    cond << "filename ~* #{ActiveRecord::Base.connection.quote(params[:filename])}" if !params[:filename].blank?
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

  def show
    @d_object = DObject.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @d_object }
      format.pdf {
        send_file(@d_object.filename_with_path,
                  :type=>@d_object.mime_type)
      }
      format.jpeg {
        if !@d_object.get_pdfimage.nil?
          img=Magick::Image.read(@d_object.get_pdfimage).first
        else
          img=Magick::Image.read(@d_object.filename_with_path).first
          img.format='jpeg'
        end
        # img.scale!(0.25)
        # img.resize_to_fit!(300, 300)
        img.resize_to_fit!(800, 800)
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
        # send_file(@d_object.get_pdfimage, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
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
