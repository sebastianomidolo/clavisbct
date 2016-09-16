class OmekaFilesController < ApplicationController

  load_and_authorize_resource only: [:upload]

  def index
  end

  def upload
    @d_object=DObject.find(params[:d_object_id])
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
end
