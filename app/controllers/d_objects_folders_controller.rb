# coding: utf-8
class DObjectsFoldersController < ApplicationController
  layout 'navbar'
  load_and_authorize_resource only: [:index,:show,:makepdf]

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

  def show
    @d_objects_folder=DObjectsFolder.find(params[:id])
    render text:'non accessibile' and return if !@d_objects_folder.readable_by?(current_user)
    @d_objects=@d_objects_folder.d_objects
    page = params[:page].blank? ? 1 : params[:page].to_i
    per_page = params[:per_page].blank? ? 50 : params[:per_page].to_i
    @d_objects=@d_objects.paginate(page:page,per_page:per_page)
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
    if f.d_objects.size==0
      f.destroy
    end
    redirect_to d_objects_folders_path
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
    end
  end


  def makepdf
    f=DObjectsFolder.find(params[:id])
    fn=f.to_pdf(params)
    send_file(fn, filename:'temp.pdf', type:'application/pdf', disposition:'inline')
  end

  def set_cover_image
    respond_to do |format|
      format.html
      format.js
    end
  end

end
