class CipesCedoRecordsController < ApplicationController
  layout 'navbar'
  def index
    # render text:'missing search term' if params[:qs].blank?
    params[:per_page]=50 if params[:per_page].blank?
    @cipes_cedo_records=CipesCedoRecord.search_all(params[:qs],params)
  end
end
