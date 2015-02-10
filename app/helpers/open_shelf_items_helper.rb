module OpenShelfItemsHelper
  def open_shelf_item_toggle(item_id, deleted)
    if user_signed_in? and [1,2,3,6,9,12,13].include?(current_user.id)
      if deleted
        lnk = link_to('Aggiungi', insert_open_shelf_item_path(item_id, format:'js'), title:'Aggiungi a scaffale aperto', class: 'btn btn-primary', remote: true, onclick: %Q{$('#item_#{item_id}').html('<b>inserimento...</b>')})
      else
        lnk = link_to('Togli', delete_open_shelf_item_path(item_id, format:'js'), title:'Togli da scaffale aperto', class: 'btn btn-danger', remote: true, onclick: %Q{$('#item_#{item_id}').html('<b>cancellazione...</b>')})
      end
    else
      # lnk = deleted ? 'magazzino' : 'scaffale aperto'
      lnk = ''
    end
  end

end
