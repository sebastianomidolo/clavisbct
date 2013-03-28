class SpSectionsController < ApplicationController
  def show
    @sp_section=SpSection.find_by_bibliography_id_and_number(params[:id],params[:number])
    @h1_title='Proposte bibliografiche'
    @h1_link="/sp_bibliographies"
    @h2_title=@sp_section.sp_bibliography.title
    @css_id='bibliografie'
    render :layout=>params[:layout] if !params[:layout].blank?
  end

end
