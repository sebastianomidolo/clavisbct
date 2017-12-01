class OmekaFilesController < ApplicationController

  load_and_authorize_resource only: [:upload]

  def index
  end

  def upload_vecchio
    @d_object=DObject.find(params[:d_object_id])
    @d_objects_folder=@d_object.d_objects_folder
    item_title=params[:item_title]
    if !item_title.blank?
      item=OmekaItem.create(params[:collection].to_i)
      item.title=item_title
      item.clavis_manifestation_id=@d_object.clavis_manifestation_id if !@d_object.clavis_manifestation_id.nil?
      fname=@d_object.filename_with_path
      if params[:load_folder].blank?
        f=OmekaFile.upload_localfile(fname, item)
        if f.class==OmekaFile
          f.derivate_images
          f.split_pdf
          f.destroy
        end
      else
        dirname=File.dirname(fname)
        p=1
        Dir.glob(File.join(dirname,"*.*")).sort.each do |f|
          new_file=OmekaFile.upload_localfile(f, item, p)
          if new_file.class==OmekaFile
            new_file.derivate_images
          end
          p+=1
        end
      end
      redirect_to "http://bctwww.comperio.it/omeka/admin/items/show/#{item.id}"
      return
    end

    @omeka_file=OmekaFile.new
  end

  def upload
    if params[:d_object_id].blank?
      @d_objects_folder=DObjectsFolder.find(params[:d_objects_folder_id])
      @d_objects=@d_objects_folder.d_objects
      @d_object=@d_objects.first
    else
      @d_object=DObject.find(params[:d_object_id])
      @d_objects_folder=@d_object.d_objects_folder
      @d_objects=@d_objects_folder.d_objects
    end
    item_title=params[:item_title]
    # TUTTO DA VERIFICARE! 29 novembre 2017
    if !item_title.blank?
      item=OmekaItem.create(params[:collection].to_i)
      item.title=item_title
      item.clavis_manifestation_id=@d_object.clavis_manifestation_id if !@d_object.clavis_manifestation_id.nil?
      fname=@d_object.filename_with_path
      if params[:load_folder].blank?
        f=OmekaFile.upload_localfile(fname, item)
        if f.class==OmekaFile
          f.derivate_images
          f.split_pdf
          f.destroy
        end
      else
        dirname=File.dirname(fname)
        p=1
        Dir.glob(File.join(dirname,"*.*")).sort.each do |f|
          new_file=OmekaFile.upload_localfile(f, item, p)
          if new_file.class==OmekaFile
            new_file.derivate_images
          end
          p+=1
        end
      end
      redirect_to "https://bcteka.comperio.it/admin/items/show/#{item.id}"
      return
    end
  end

end
