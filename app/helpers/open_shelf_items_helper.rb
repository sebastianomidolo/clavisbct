module OpenShelfItemsHelper
  def open_shelf_item_toggle(item_id, deleted, dest_section=nil)
    if item_id.class == ClavisItem
      clavis_item = item_id
      item_id = item_id.id
    else
      clavis_item = nil
    end

    if !deleted
      open_shelf_item = OpenShelfItem.find(item_id)
      os_section = "Sezione: #{open_shelf_item.os_section}"
    else
      os_section = ''
    end

    if user_signed_in? and [1,2,3,6,9,12,13].include?(current_user.id)
      if deleted
        disabled = dest_section.blank? ? true : false
        lnk = link_to('Aggiungi', insert_open_shelf_item_path(item_id, format:'js', dest_section:dest_section), title:"Aggiungi a scaffale aperto #{dest_section}", class: 'btn btn-primary', remote: true, disabled:disabled, onclick: %Q{$('#item_#{item_id}').html('<b>inserimento...</b>')})
      else
        if open_shelf_item.created_by == current_user.id
          disabled = false
          btn_text = 'Togli'
        else
          disabled = true
          btn_text = "Inserito da #{User.find(open_shelf_item.created_by).email}"
        end
        lnk = link_to(btn_text, delete_open_shelf_item_path(item_id, format:'js', dest_section:dest_section), title:"Togli da scaffale aperto #{dest_section}", class: 'btn btn-danger', remote: true, disabled: disabled, onclick: %Q{$('#item_#{item_id}').html('<b>cancellazione...</b>')})
        lnk += open_shelf_item.os_section
      end
      lnk
    else
      # lnk = deleted ? 'magazzino' : 'scaffale aperto'
      lnk = os_section
    end
  end

  def open_shelf_dewey_list(records)
    res=[]
    records.each do |r|
      res << open_shelf_dewey_list_row(r)
    end
    res=content_tag(:tbody, res.join("\n").html_safe)
    res=content_tag(:table, res, {class: 'table table-striped'})
  end

  def open_shelf_dewey_list_row(r,titles=[])
    res=[]
    lnk = titles.size == 0 ? link_to(r['dewey'], titles_open_shelf_items_path(format:'js',class_id:r['class_id']) ,remote: true) : r['dewey']
    res << content_tag(:tr, content_tag(:td, lnk) +
                content_tag(:td, r['count']), id:"class_#{r['class_id']}")
    titles.each do |t|
      # da completare:
      res << content_tag(:tr, content_tag(:td, t))
    end
    res.join.html_safe
  end

end
