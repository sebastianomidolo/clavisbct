module AttachmentsHelper
  def attachments_render(attachments)
    dob=[]
    attachments.reorder('position').each do |a|
      dob << a.d_object
    end
    d_objects_render(dob)
  end
end
