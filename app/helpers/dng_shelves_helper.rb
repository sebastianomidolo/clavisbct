module DngShelvesHelper
  def dng_shelves_list(records)
    res=[]
    records.each do |r|
      lnk=link_to(r.Name, dng_shelf_path(r.ID))
      res << content_tag(:tr,
                         content_tag(:td, lnk) +
                         content_tag(:td, "Creato da: #{r.OwnerID}")
                        )
    end
    res=content_tag(:tbody, res.join.html_safe)
    content_tag(:table, res, {class: 'table table-striped'})
  end
end
