class DngShelvesController < ApplicationController
  layout 'navbar'

  def index
    @dng_shelves=DngShelf.where(%Q{"ClassName" = 'ManifestationsShelf' AND "SerializedData" != 'N;'
           AND "Visibility"='public'}).order('"Name"')
  end

  def show
    @dng_shelf = DngShelf.find(params[:id])
  end

end
