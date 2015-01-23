class HomeController < ApplicationController
  layout 'navbar'

  # before_filter :authenticate_user!
  def index
    @pagetitle="ClavisBCT"
    @msg=Time.now
    # authenticate_user!
  end

  def jsonip
    headers['Access-Control-Allow-Origin'] = "*"
    headers['Access-Control-Allow-Methods'] = "GET"
    render json: {ip: DngSession.format_client_ip(request)}.to_json
  end

  def periodici_musicale_in_ritardo
  end

  def spazioragazzi
    render :text=>File.read('/tmp/indexfile.html')
  end

  def uni856
    @pagetitle='Titoli in Clavis con URL (unimarc tag 856)'
    sql=%Q{select trim(cm.title) as title,u.* from clavis.uni856 u
        join clavis.manifestation cm using(manifestation_id)
         order by lower(u.nota),cm.sort_text}
    @records=ActiveRecord::Base.connection.execute(sql)
  end

  def iccu_link
    if !params[:bid].blank?
      @url=ClavisManifestation.new(bid_source: 'SBN', bid: params[:bid]).iccu_opac_url
    end
  end
end

