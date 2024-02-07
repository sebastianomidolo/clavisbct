# coding: utf-8

class SbctUsersController < ApplicationController
  layout 'sbct'
  before_filter :authenticate_user!

  def show
    if current_user.id!=(params[:id].to_i)
      render text:'no no' and return
    end
    @sbct_user = SbctUser.find(params[:id])
  end

  # Imposta la biblioteca di default per la sessione corrente
  def set_default_library
    if current_user.id!=(params[:id].to_i)
      render text:'no no' and return
    end
    library_id=params[:library_id].to_i

    ids = current_user.clavis_libraries.collect {|i| i.id}
    if ids.include?(library_id)
      cl=current_user.clavis_librarian
      cl.default_library_id=library_id
      cl.save
      redirect_to sbct_user_path(current_user)
    else
      render text:"Biblioteca richiesta #{library_id} non abilitata in Clavis per utente #{current_user.email}"
    end

  end

  
end
