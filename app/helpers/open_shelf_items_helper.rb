module OpenShelfItemsHelper
  def open_shelf_item_toggle(item_id, deleted)
    if user_signed_in?
      if deleted
        lnk = link_to('Inserisci', insert_open_shelf_item_path(item_id, format:'js'), class: "btn btn-primary", remote: true, onclick: %Q{$('#item_#{item_id}').html('<b>inserimento...</b>')})
      else
        lnk = link_to('Cancella', delete_open_shelf_item_path(item_id, format:'js'), class: "btn btn-danger", remote: true, onclick: %Q{$('#item_#{item_id}').html('<b>cancellazione...</b>')})
      end
    else
      # lnk = deleted ? 'magazzino' : 'scaffale aperto'
      lnk = ''
    end
  end

end
