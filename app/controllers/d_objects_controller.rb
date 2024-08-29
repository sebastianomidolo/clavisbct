require 'RMagick'

class DObjectsController < ApplicationController
  layout 'navbar'
  # before_filter :authenticate_user!, only: [:upload]
  load_and_authorize_resource only: [:index,:view,:list_folder_content,:makepdf,:upload,:edit,:destroy,:set_as_cover_image,:download]


  def index
    cond=[]
    cond << "mime_type='#{params[:mime_type]}'" if !params[:mime_type].blank?
    cond << "filename ~* #{ActiveRecord::Base.connection.quote(params[:filename])}" if !params[:filename].blank?
    if !params[:tags].blank?
      ts=DObject.connection.quote_string(params[:tags].split.join(' & '))
      cond << "to_tsvector('simple', tags::text) @@ to_tsquery('simple', '#{ts}')"
      # cond << "tags::text ~* #{ActiveRecord::Base.connection.quote(params[:tags])}"
    end
    cond = cond.join(" AND ")
    cond = "false" if cond.blank?
    order='name'
    @d_objects = DObject.paginate(:conditions=>cond,
                                  :page=>params[:page],
                                  :order=>order)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @d_objects }
    end
  end

  def download
    @d_object=DObject.find(params[:id])
    send_file(@d_object.filename_with_path, :filename=>File.basename(@d_object.filename), :type=>'application/octet-stream', :disposition => 'inline')
  end

  def list_folder_content
    @d_object=DObject.find(params[:id])
    @d_objects=@d_object.folder_content(params)
  end

  def makepdf
    d_object=DObject.find(params[:id])
    fn=d_object.to_pdf(params)
    send_file(fn, filename:'temp.pdf', type:'application/pdf', disposition:'inline')
  end

  def edit
    render text:'forbidden' and return if !@d_object.writable_by?(current_user)
    if @d_object.tags.blank?
      @d_object.tags='<r></r>'
      @d_object.save
    end
  end

  def destroy
    d_object=DObject.find(params[:id])
    render text:'forbidden' and return if !d_object.writable_by?(current_user)
    @d_objects_folder=d_object.d_objects_folder
    d_object.destroy
    redirect_to d_objects_folder_path(@d_objects_folder)
  end

  # Imposta come immagine di copertina (sottinteso: del folder che lo contiene)
  def set_as_cover_image
    o=DObject.find(params[:id])
    render text:'forbidden' and return if !o.writable_by?(current_user)
    f=o.d_objects_folder
    f.write_tags_from_filename if f.tags.nil?
    if params[:checked]=='true'
      f.cover_image=o.id
      f.save if f.changed?
    else
      f.cover_image=nil
      f.set_cover_image
    end
  end

  def update
    @d_object = DObject.find(params[:id])
    respond_to do |format|
      if @d_object.update_attributes(params[:d_object])
        format.html { render :action => "view" }
      else
        format.html { render :action => "edit" }
      end
      format.json { respond_with_bip(@d_object) }
    end
  end
  
  def view
    @d_object = DObject.find(params[:id])
    @d_objects_folder = @d_object.d_objects_folder
    @dopf = DObjectsPersonalFolder.find(user_session[:d_objects_personal_folder]) if !user_session[:d_objects_personal_folder].nil?

    render text:'non accessibile' and return if !@d_objects_folder.readable_by?(current_user)

    respond_to do |format|
      format.html {}
      format.jpeg {
        if @d_object.mime_type.split(';').first=='application/pdf'
          page = params[:page].blank? ? 1 : params[:page].to_i
          page = @d_object.pdf_count_pages if page > @d_object.pdf_count_pages
          if ! File.exists?(@d_object.pdf_filename_for_jpeg(page))
            @d_object.pdf_to_jpeg
          end
          img=Magick::Image.read(@d_object.pdf_filename_for_jpeg(page)).first
        else
          img=Magick::Image.read(@d_object.filename_with_path).first
        end
        # img=img.blue_shift
        if current_user.email=='seba'
          img = @d_object.watermark_for_image(img)
        end
        img.format='jpeg'
        if !params[:size].blank?
          s=params[:size].split('x')
          if s[1].blank?
            img.resize_to_fit!(s[0].to_i)
          else
            img.resize_to_fit!(s[0].to_i,s[1].to_i)
          end
        else
          # img.resize_to_fit!(300)
        end
        # send_file(@d_object.filename_with_path, :filename=>File.basename(@d_object.filename), :type => 'image/jpeg; charset=binary', :disposition => 'inline')
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
      }
    end
  end

  def myfolderxxx
    @d_object = DObject.find(params[:id])
    user_session[:d_objects_ids] = [] if user_session[:d_objects_ids].nil?
    if request.method=="POST"
      user_session[:d_objects_ids] << @d_object.id
    end
    if request.method=="DELETE"
      user_session[:d_objects_ids].delete(@d_object.id)
    end
    user_session[:d_objects_ids].uniq!
    pf=DObjectsPersonalFolder.find_or_create_by_owner_id(current_user.id)
    user_session[:d_objects_ids] = DObjectsFolder.virtual_d_objects_sort(user_session[:d_objects_ids])
    pf.d_objects=user_session[:d_objects_ids].join(',')
    pf.d_objects=DObjectsFolder.virtual_d_objects_sort(pf.d_objects)
    pf.save
  end

  def myfolder
    return if user_session[:d_objects_personal_folder].nil?
    @d_object = DObject.find(params[:id])
    @dopf = DObjectsPersonalFolder.find(user_session[:d_objects_personal_folder])
    ids = @dopf.ids
    if request.method=="POST"
      ids << @d_object.id
    end
    if request.method=="DELETE"
      ids.delete(@d_object.id)
    end
    @dopf.ids=ids.uniq
    @dopf.save
  end

  def upload
    @d_objects_folder=DObjectsFolder.find(params[:d_objects_folder_id])
    render text:'forbidden' and return if !@d_objects_folder.writable_by?(current_user)
    if request.method=="POST"
      uploaded_io = params[:filename]
      if uploaded_io.nil?
        render :template=>'d_objects/file_non_specificato'
      else
        @d_object = DObject.new.save_new_record(params,current_user)
        redirect_to @d_objects_folder
      end
    else
      @d_object = DObject.new
      @d_object.d_objects_folder_id=params[:d_objects_folder_id]
    end
  end

  def show
    if !params[:filename].blank?
      sql="SELECT * FROM d_objects WHERE filename ~ '#{ActiveRecord::Base.connection.quote_string(params[:filename])}$'"
      @d_object = DObject.find_by_sql(sql).first
    else
      @d_object = DObject.find(params[:id])
    end
    @d_object.access_right_id=0 if can? :search, DObject
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
    if !can? :search, DObject
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
        logo = Magick::Image.read("/home/storage/preesistente/testzone/bctcopyr.png").first
        if !@d_object.get_pdfimage.nil?
          img=Magick::Image.read(@d_object.get_pdfimage).first
        else
          img=Magick::Image.read(@d_object.filename_with_path).first
          img.format='jpeg'
        end
        # img.scale!(0.25)
        # img.resize_to_fit!(300, 300)
        
        if !params[:size].blank?
          s=params[:size].split('x')
          img.resize_to_fit!(s[0].to_i)
        else
          # img.resize_to_fit!(800, 800)
        end
        logo.resize_to_fit!(img.columns - img.columns/5)
        # logo=logo.wave

        # http://www.imagemagick.org/RMagick/doc/image3.html#watermark
        # img=img.watermark(logo,0.1,0.5,Magick::NorthGravity,0,0)
        # img=img.watermark(logo,0.1,0.5,Magick::SouthGravity,0,0)
        # img=img.watermark(logo,0.5,0.5,Magick::SouthGravity,0,0)
        img=img.dissolve(logo,0.25,0.5,Magick::SouthGravity,0,0)

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

  # Rendering oggetto digitale senza autenticazione
  def dnl
    mid=params[:manifestation_id]
    if mid.blank?
      @d_object = DObject.find(params[:id])
    else
      if mid.to_i==0
        @d_object = DObject.find(1034649)
      else
        cm=ClavisManifestation.find(params[:manifestation_id])
        @d_object = cm.clavis_cover_cached
        @d_object = cm.clavisbct_cover if @d_object.nil?
      end
    end
    @d_object = DObject.find(1034649) if @d_object.nil?

    if @d_object.access_right_id==0
      @pagetitle="#{@d_object.id} - #{@d_object.filename}"
    else
      @pagetitle="#{@d_object.id} accesso non autorizzato"
      render text:"non autorizzato d_object_id #{@d_object.id}", layout:'d_objects'
      return
    end
    respond_to do |format|
      format.html { render layout:'d_objects' }
      format.json { render json: @d_object }
      format.pdf {
        send_file(@d_object.filename_with_path, :type=>@d_object.mime_type)
      }
      format.jpeg {
        page=params[:page]
        if !@d_object.get_pdfimage(page).nil?
          img=Magick::Image.read(@d_object.get_pdfimage(page)).first
        else
          img=Magick::Image.read(@d_object.filename_with_path).first
          img.format='jpeg'
        end
        if !params[:size].blank? and @d_object.name!='nocover.jpg'
          width,height=params[:size].split('x').map {|e| e.to_i}
          if params[:crop].blank?
            img.resize_to_fit!(width, height)
          else
            img.resize_to_fill!(width, height, Magick::NorthGravity)
          end
        else
          # img.resize_to_fit!(800, 800)
        end
        # logo = Magick::Image.read("/home/storage/preesistente/testzone/bctcopyr.png").first
        # logo.resize_to_fit!(img.columns - img.columns/5)
        # img=img.dissolve(logo,0.25,0.5,Magick::SouthGravity,0,0)
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
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
  end

  def dnl_pdf
    @d_object = DObject.find(params[:id])
    if @d_object.access_right_id==0
      @pagetitle="#{@d_object.id} - #{@d_object.filename}"
    else
      @pagetitle="#{@d_object.id} accesso non autorizzato"
      render text:"non autorizzato d_object_id #{@d_object.id}", layout:'d_objects'
      return
    end
    page=params[:page]
    respond_to do |format|
      format.html { render layout:'d_objects' }
      format.jpeg {
        img=Magick::Image.read(@d_object.get_pdfimage(page)).first
        if !params[:size].blank?
          width,height=params[:size].split('x').map {|e| e.to_i}
          if params[:crop].blank?
            img.resize_to_fit!(width, height)
          else
            img.resize_to_fill!(width, height, Magick::NorthGravity)
          end
        end
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
      }
    end
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
