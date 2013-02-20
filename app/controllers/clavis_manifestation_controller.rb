# lastmod 20 febbraio 2013

class ClavisManifestationController < ApplicationController
  def kardex
    @clavis_manifestation=ClavisManifestation.find(params[:id])
  end
end
