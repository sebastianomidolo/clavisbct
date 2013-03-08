class ProculturaFoldersController < ApplicationController
  def index
    archive_id=params[:archive_id]
    logger.warn("reqfrom: #{params[:reqfrom]}")
    if !archive_id.blank?
      @procultura_archive=ProculturaArchive.find(archive_id)
      render :partial=>'lista'
    else
      render :partial=>'indice'
    end
  end

  def show
    @pf=ProculturaFolder.find(params[:id])
    render :layout=>nil
  end
end
