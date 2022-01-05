# lastmod 21 dicembre 2012
# lastmod 19 dicembre 2012

class ClavisAuthoritiesController < ApplicationController
  # load_and_authorize_resource only: [:index]
  
  def index
    render template:'clavis_authorities/l_in_subjects' and return if params[:in_subjects]=='true'
    render template:'clavis_authorities/l_in_keywords' and return if params[:in_keywords]=='true'
    cond=[]
    if params[:authority_type].blank?
      cond << 'authority_type is null'
    else
      if params[:authority_type]!='all'
        cond << "authority_type=#{ClavisAuthority.connection.quote(params[:authority_type])}"
      end
    end
    cond << "bid is not null" if params[:bidnotnull]=='true'
    cond << "bid is null" if params[:bidnotnull]=='false'
    cond << "authority_rectype = #{ClavisAuthority.connection.quote(params[:rectype])}" if !params[:rectype].blank?
    cond << "full_text ~* #{ClavisAuthority.connection.quote(params[:qs])}" if !params[:qs].blank?
    cond = cond.join(' AND ')
    order=params[:sort].blank? ? 'sort_text' : params[:sort]
    @sql_conditions=cond
    @clavis_authorities=ClavisAuthority.paginate(:conditions=>cond,per_page:400,
                                               :page=>params[:page],
                                               :order=>order)
  end

  def info
    headers['Access-Control-Allow-Origin'] = "*"
    sql=%Q{SELECT r.value_label as rectype,t.value_label as authtype, a.bid_source,
  full_text as heading,authority_id,subject_class,bid as term_resource,
   (xpath('//d300/sa/text()',unimarc::xml))[1] as note
  FROM clavis.authority a
  JOIN clavis.lookup_value t
  ON(t.value_key=a.authority_type and t.value_language='it_IT'
   AND t.value_class='AUTHTYPE')
  JOIN clavis.lookup_value r
  ON(r.value_key=a.authority_rectype AND r.value_language='it_IT'
   AND r.value_class='AUTHRECTYPE')
 WHERE authority_id=#{params[:id]}}

    r=ActiveRecord::Base.connection.execute(sql)
    respond_to do |format|
      format.json { render :json => r.first }
    end
  end

  def show
    @ca=ClavisAuthority.find(params[:id])
    r={}
    r[:clavis_authority]=@ca
    r[:letterebct]=@ca.letterebct_person
    render xml:r.to_xml
  end

  def dupl
    @authorities=ClavisAuthority.dupl(params[:authority_type])
  end

end
