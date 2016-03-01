class HomeController < ApplicationController
  layout 'navbar'
  # before_filter :authenticate_user!, only: 'bidcr'


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

  def test
    render :text=>File.read('/home/storage/preesistente/static/changelog_test.html'), :layout=>true
  end


  def bidcr
    u=ActiveRecord::Base.connection.quote(params[:user])
    d=params[:days].to_i
    bid_source = params[:bid_source].blank? ? '' : " AND bid_source='#{params[:bid_source]}'"
    sql=%Q{select title,bid,bid_source,date_created,date_updated from clavis.manifestation where created_by = #{u} and date_created>now()-interval '#{d} days' #{bid_source} order by date_created}
    @records=ActiveRecord::Base.connection.execute(sql).to_a
    sql=%Q{select date_trunc('hour',date_created) as date_created,count(*) from clavis.manifestation where created_by = #{u} and date_created>now()-interval '#{d} days' group by date_trunc('hour',date_created) order by date_created}
    @sommario=ActiveRecord::Base.connection.execute(sql).to_a
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

