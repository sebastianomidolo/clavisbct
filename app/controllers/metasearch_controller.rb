# lastmod 26 gennaio 2013

include MetaSearch

class MetasearchController < ApplicationController
  def search
    headers['Access-Control-Allow-Origin'] = "*"
    q=params[:q]
    sys=params[:sys]
    if q.blank?
      res={}
    else
      # true=>debug mode (default false)
      res=do_search(sys,q,params[:dryrun],false)
    end
    respond_to do |format|
      format.html { render :text=>res.inspect }
      format.json { render :json => res }
    end
  end
  def redir
    url=redirect_url(params[:sys],params[:q])
    if url.nil?
      render :text=>'no way'
    else
      redirect_to(url)
    end
  end
end
