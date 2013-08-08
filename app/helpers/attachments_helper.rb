module AttachmentsHelper

  def attachments_render(attachments)
    att=attachments.group_by {|a| a.folder}
    res=[]
    att.keys.sort.each do |k|
      res << content_tag(:div, content_tag(:b, k.capitalize)) if !k.nil?
      a=att[k]
      atc=a.sort {|x,y| x.position<=>y.position}
      dob=[]
      atc.each do |x|
        # res << content_tag(:h3, x.d_object.id)
        dob << x.d_object
      end
      res << content_tag(:div, d_objects_render(dob))
    end
    content_tag(:div, res.join.html_safe)
  end

end
