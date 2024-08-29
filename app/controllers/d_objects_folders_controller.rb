# coding: utf-8
class DObjectsFoldersController < ApplicationController
  layout 'navbar'
  load_and_authorize_resource only: [:index,:destroy,:delete_contents,:users]
  before_filter :set_d_object_folder, only: [:show,:set_pdf_params,:makepdf,:derived,:pagenumbers]


  def index_old
    cond=[]
    if !params[:tags].blank?
      ts=DObject.connection.quote_string(params[:tags].split.join(' & '))
      cond << "to_tsvector('simple', tags::text) @@ to_tsquery('simple', '#{ts}')"
    end
    cond << "name like '#{DObject.connection.quote_string(params[:basefolder])}%'" if !params[:basefolder].blank?
    cond = cond.join(" AND ")
    if cond.blank?
      cond = "false"
    else
      @do_search = true
    end
    order='lower(name)'
    @d_objects_folders = DObjectsFolder.paginate(conditions:cond, page:params[:page], order:order)
  end

  def index
    # user_session[:d_objects_ids] = [1393848, 1393841, 1393885, 1393887, 1393859, 1393907, 1393863, 1393882, 1393831, 1393833, 1393876, 1393917, 1393894, 1393825, 1393884, 1393869, 1393913, 1393910, 1393890, 1393847, 1393903, 1393905] if current_user.email=='seba'
    if params[:pf].nil?
      @dopf=DObjectsPersonalFolder.find_or_create_by_owner_id(current_user.id)
    else
      @dopf=DObjectsPersonalFolder.find(params[:pf].to_i)
    end
    user_session[:d_objects_personal_folder] = @dopf.id
          
    if !params[:dirname].blank?
      @d_objects_folder=DObjectsFolder.find_by_name(params[:dirname])
      if @d_objects_folder.nil?
        render text:"Non trovato: #{params[:dirname]}",layout:true and return
      else
        redirect_to @d_objects_folder
      end
    end

    cond=[]
    params[:folders_only]=1 if params[:tags].blank?
    if params[:folders_only].blank?
      if !params[:tags].blank?
        ts=DObject.connection.quote_string(params[:tags].split.join(' & '))
        cond << "(to_tsvector('simple', f_tags::text) @@ to_tsquery('simple', '#{ts}') OR to_tsvector('simple', o_tags::text) @@ to_tsquery('simple', '#{ts}'))"
      end
      cond << "f.name like '#{DObject.connection.quote_string(params[:basefolder]).chomp('/')}%'" if !params[:basefolder].blank?
      cond = cond.join(" AND ")
      if cond.blank?
        cond = "false"
      else
        @do_search = true
      end
      @sql=%Q{SELECT DISTINCT f.name,f.id,f.tags::text FROM dobjects dox LEFT JOIN d_objects_folders f ON(f.id=dox.f_id)
             JOIN d_objects_folders_users fu
                 ON( (fu.d_objects_folder_id=f.id OR f.name || '/' LIKE fu.pattern || '%')
              AND fu.user_id=#{current_user.id}) WHERE #{cond}}
      order='lower(f_name)'
      @d_objects_folders = DObjectsFolder.paginate_by_sql(@sql, page:params[:page], order:order)
    else
      if !params[:tags].blank?
        ts=DObject.connection.quote_string(params[:tags].split.join(' & '))
        cond << "to_tsvector('simple', tags::text) @@ to_tsquery('simple', '#{ts}')"
      end
      cond << "name like '#{DObject.connection.quote_string(params[:basefolder])}%'" if !params[:basefolder].blank?
      cond = cond.join(" AND ")
      if cond.blank?
        cond = "false"
      else
        @do_search = true
      end
      @sql=%Q{SELECT f.* FROM d_objects_folders f
             JOIN d_objects_folders_users fu
                  ON( (fu.d_objects_folder_id=f.id OR f.name LIKE fu.pattern || '%')
              AND fu.user_id=#{current_user.id}) WHERE #{cond}}
      order='lower(name)'
      # @d_objects_folders = DObjectsFolder.paginate(conditions:cond, page:params[:page], order:order)
      @d_objects_folders = DObjectsFolder.paginate_by_sql(@sql, page:params[:page], order:order)
    end
  end

  def pagenumbers
    if params[:azzera].blank?
      @d_objects_folder.add_tag_x_pp
    else
      @d_objects_folder.remove_tag_x_pp
    end
    redirect_to d_objects_folder_path(view:'list')
  end

  def show
    # render text:'x' and return
    if !params[:add_user_id].blank?
      u=User.find(params[:add_user_id])
      @d_objects_folder.enable_user_by_folder_name(u)
      # render text:"aggiungi folder #{@d_objects_folder.id} per utente #{u.id}"  and return
      redirect_to users_d_objects_folders_path(user_id:u.id,mode:'add_folder')
    end

    if params[:id].to_i == 0
      # render text:@dopf.ids and return
      @d_objects=@dopf.elements
    else
      render text:'non accessibile' and return if !@d_objects_folder.readable_by?(current_user)
      @d_objects=@d_objects_folder.d_objects
    end
    @pagetitle="#{@d_objects_folder.name}"

    page = params[:page].blank? ? 1 : params[:page].to_i
    if params[:view]=='list'
      per_page = @d_objects.size
    else
      per_page = params[:per_page].blank? ? 200 : params[:per_page].to_i
    end
    @d_objects=@d_objects.paginate(page:page,per_page:per_page)
    # render text:"#{@pagetitle} debug on per user #{current_user.email}" and return if current_user.email=='seba'
    # render template:'d_objects_folders/show_orig' if current_user.email=='seba'
  end

  def makedir
    @d_objects_folder=DObjectsFolder.find(params[:id])
    render text:'azione non permessa' and return if !@d_objects_folder.writable_by?(current_user)
    if request.put?
      foldername=params[:foldername]
      new_folder=@d_objects_folder.makedir(foldername)
      redirect_to d_objects_folder_path(new_folder)
    end
  end

  def edit
    @d_objects_folder = DObjectsFolder.find(params[:id])
    if @d_objects_folder.tags.blank?
      @d_objects_folder.tags='<r></r>'
      @d_objects_folder.save
    end
    @d_objects_folder.write_tags_from_filename
  end

  def destroy
    f=DObjectsFolder.find(params[:id])
    parent=f.parent
    if f.d_objects.size==0
      f.destroy
    end
    if parent.nil?
      redirect_to d_objects_folders_path
    else
      redirect_to parent
    end
  end

  def delete_contents
    f=DObjectsFolder.find(params[:id])
    f.delete_contents(current_user)
    redirect_to f
  end

  def update
    @d_objects_folder = DObjectsFolder.find(params[:id])
    respond_to do |format|
      if @d_objects_folder.update_attributes(params[:d_objects_folder])
        format.html {
          @d_objects=@d_objects_folder.d_objects
          page = params[:page].blank? ? 1 : params[:page].to_i
          per_page = params[:per_page].blank? ? 50 : params[:per_page].to_i
          @d_objects=@d_objects.paginate(page:page,per_page:per_page)
          render :action => "show"
        }
      else
        format.html { render :action => "edit" }
      end
      format.json { respond_with_bip(@d_objects_folder) }
    end
  end

  def set_pdf_params
  end

  def makepdf
    @d_objects_folder.access_right_id=params[:access_right_id].to_i
    params[:force] = params[:overwrite]=='1' ? true : false
    params[:nologo] = params[:include_logo].blank? ? true : false
    @d_objects_folder.pdf_params={include_logo:params[:include_logo],resize_ratio:params[:resize_ratio],access_right_id:params[:access_right_id],gray_scale:params[:gray_scale]}
    fn=@d_objects_folder.to_pdf(params)
    @d_objects_folder.save if @d_objects_folder.id!= 0 and  @d_objects_folder.changed?
    respond_to do |format|
      format.pdf {
        send_file(fn, filename:'temp.pdf', type:'application/pdf', disposition:'inline')
      }
      format.js {
      }
    end
  end

  def set_cover_image
    respond_to do |format|
      format.html
      format.js
    end
  end

  def download
    @d_objects_folder=DObjectsFolder.find(params[:id])
    render text:'azione non permessa' and return if current_user.email!='seba'
  end

  def filenames
    @d_objects_folder=DObjectsFolder.find(params[:id])
    render text:'azione non permessa' and return if !@d_objects_folder.writable_by?(current_user)
    d_objects=@d_objects_folder.d_objects
    @d_objects=d_objects.paginate(page:1,per_page:d_objects.size)
  end

  def derived
    if @d_objects_folder.x_mid.blank?
      if @d_objects_folder.x_ti.blank?
        filename="temp_#{@d_objects_folder.id}.pdf"
      else
        filename="#{@d_objects_folder.x_ti}.pdf"
      end
    else
      cm=ClavisManifestation.find(@d_objects_folder.x_mid)
      filename=cm.title.strip
    end
    render(text:"Risorsa non accessibile", content_type:'text/plain') and return if @d_objects_folder.access_right_id!=0
    respond_to do |format|
      format.html {render :text=>"folder: #{@d_objects_folder.derived_pdf_filename}"}
      format.pdf {
        send_file(@d_objects_folder.derived_pdf_filename, filename:filename, type:'application/pdf', disposition:'inline')
      }
    end
  end

  def access_by_name_old
    foldername = params[:foldername].gsub(':','/')
    dobf=DObjectsFolder.find_by_name(foldername)
    render text:'---' if dobf.nil?
    redirect_to dobf
  end

  def access_by_name
    foldername = DObjectsFolder.connection.quote(params[:p])
    # render text:foldername and return
    sql = "SELECT * from d_objects_folders where name = #{foldername}"
    dobf=DObjectsFolder.find_by_sql(sql)
    # render text:sql and return
    render text:'---notfound---' and return if dobf.nil?
    redirect_to controller: 'd_objects_folders', id:dobf, action: 'show', view: 'list'
    # redirect_to dobf
  end

  def users
    @user=User.find(params[:user_id])
  end

  private
  def set_d_object_folder
    if params[:id].to_i == 0
      @dopf = DObjectsPersonalFolder.find(user_session[:d_objects_personal_folder])
      @d_objects_folder=DObjectsFolder.virtual(current_user, @dopf.ids)
    else
      @d_objects_folder = DObjectsFolder.find(params[:id])
    end
  end

  
end
