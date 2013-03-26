class SpSectionsController < ApplicationController
  def show
    @sp_section=SpSection.find_by_bibliography_id_and_number(params[:id],params[:number])
  end

end
