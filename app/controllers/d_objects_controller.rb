require 'RMagick'

class DObjectsController < ApplicationController
  layout 'navbar'
  before_filter :authenticate_user!, only: [:upload]


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

  def upload
    @backend=params[:backend]
    if request.method=="POST"
      if @backend.camelcase.constantize.new.respond_to?('save_new_record')
        @backend.camelcase.constantize.new.send('save_new_record', params)
      end
    else
      @d_object = DObject.new
    end
    if !@backend.blank?
      render template:"d_objects/#{@backend}_upload"
    end
  end

  def show
    if !params[:filename].blank?
      sql="SELECT * FROM d_objects WHERE filename ~ '#{ActiveRecord::Base.connection.quote_string(params[:filename])}$'"
      @d_object = DObject.find_by_sql(sql).first
    else
      @d_object = DObject.find(params[:id])
    end
    respond_to do |format|
      format.html {
      }
      format.jpeg {
        if (@d_object.access_right_id==0 and @d_object.mime_type=='application/pdf; charset=binary' and !params[:page].blank?)
          fname=@d_object.pdf_to_jpeg[params[:page].to_i]
          send_file(fname, :type=>'image/jpeg; charset=binary', :disposition => 'inline')
        else
          render text: "Non accessibile", :content_type=>'text/plain'
        end
      }
      format.pdf {
        if @d_object.access_right_id==0 and @d_object.mime_type=='application/pdf; charset=binary'
          send_file(@d_object.filename_with_path, :filename=>File.basename(@d_object.filename), :type=>'application/pdf', :disposition => 'inline')
        else
          render text: "Non accessibile", :content_type=>'text/plain'
        end
      }
      format.doc {
        if @d_object.access_right_id==0 and @d_object.mime_type=='application/msword; charset=binary'
          send_file(@d_object.filename_with_path, :filename=>File.basename(@d_object.filename), :type=>'application/msword', :disposition => 'inline')
        else
          render text: "Non accessibile", :content_type=>'text/plain'
        end
      }
      format.mp3 {
        cnt = params[:t].blank? ? nil : params[:t].to_i
        if @d_object.audioclip_exists?(cnt)
          send_file(@d_object.audioclip_filename(cnt), :type=>'audio/mpeg; charset=binary', :disposition => 'inline')
        else
          render text: "fname: #{fname}", :content_type=>'text/plain'
        end
      }
    end
  end

  def objshow
    @d_object = DObject.find(params[:id])
    key=Digest::MD5.hexdigest(@d_object.filename)
    if key!=params[:key]
      key=Digest::MD5.hexdigest(@d_object.libroparlato_audioclip_filename)
      if key==params[:key]
        tmp_id=@d_object.id
        @d_object = DObject.new(filename: @d_object.libroparlato_audioclip_filename, access_right_id: 0, mime_type: 'audio/mpeg; charset=binary')
        @d_object.id=tmp_id
      end
    end
    if key!=params[:key]
      render :text=>"error #{request.remote_ip}", :content_type=>'text/plain'
      return
    end
    ack=DngSession.access_control_key(params,request)
    if ack!=params[:ac]
      respond_to do |format|
        format.html {
          render :template=>'d_objects/show_restricted'
        }
        format.mp3 {
          if @d_object.audioclip_exists?
            fname=@d_object.libroparlato_audioclip_filename
          else
            fname=@d_object.filename_with_path
          end
          send_file(fname, :type => @d_object.mime_type, :disposition => 'inline')
        }
      end
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
        # logo = Magick::Image.read("/home/storage/preesistente/testzone/logo.jpg").first
        logo = Magick::Image.read("/home/storage/preesistente/testzone/bctcopyr.gif").first
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
        # img=img.watermark(logo,0.1,0.5,Magick::NorthGravity,0,0)
        # img=img.watermark(logo,0.1,0.5,Magick::SouthGravity,0,0)
        img=img.watermark(logo,0.5,0.5,Magick::SouthGravity,0,0)

        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
        # send_file(@d_object.get_pdfimage, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
      }
      format.mp3 {
        if @d_object.audioclip_exists?
          fname=@d_object.libroparlato_audioclip_filename
        else
          fname=@d_object.filename_with_path
        end
        # render text: "=> #{fname}", :content_type=>'text/plain'
        # return
        send_file(fname, :type => @d_object.mime_type, :disposition => 'inline')
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

  def random_mp3
    headers['Access-Control-Allow-Origin'] = "*"
    @pagetitle='Traccia audio casuale'
    # @d_object = Attachment.first(:conditions=>"attachment_category_id='E'", :order=>'random()').d_object
    sql=%Q{select a.* from attachments a join clavis.attachment ca on(a.attachable_id=ca.object_id)
        and ca.object_type='Manifestation' and a.attachable_type='ClavisManifestation'
        and a.attachment_category_id='E' order by random() limit 1}
    @d_object = Attachment.find_by_sql(sql).first.d_object

    # @d_object = DObject.find(5403645)
    fname=@d_object.filename_with_path
    logger.warn("random_mp3 id #{@d_object.id} (#{fname})")
    @guess = params[:guess].blank? ? false : true
    respond_to do |format|
      format.html {render :layout=>'navbar_nomenu'}
      format.js {@targetdiv=params[:targetdiv]}
    end
  end
end
