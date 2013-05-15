module AttachmentsHelper
  def attachments_render(attachments)
    dob = DObject.find(attachments.collect {|x| x.d_object_id}, :order=>'lower(filename)')
    d_objects_render(dob)
  end
    
end
