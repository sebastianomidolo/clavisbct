# coding: utf-8
class TalkingBookDownloadsController < ApplicationController
  layout 'talking_books'
  load_and_authorize_resource

  # layout 'navbar'
  def index
    @pagetitle='Downloads libro parlato BCT'
    TalkingBook.read_apache_log
    TalkingBookDownload.update_from_log_opac("/home/storage/download_libro_parlato_da_opac.log")
    @talking_book_download = TalkingBookDownload.new(params[:talking_book_download])
    @downloads = TalkingBookDownload.tutti(params)
  end
end
