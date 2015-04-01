# lastmod 21 dicembre 2012
# lastmod 19 dicembre 2012

class ClavisAuthoritiesController < ApplicationController

  def index
    cond=[]
    cond << "authority_type=#{ClavisAuthority.connection.quote(params[:authority_type])}"
    cond << "bid is not null" if params[:bidnotnull]=='true'
    cond << "bid is null" if params[:bidnotnull]=='false'
    cond = cond.join(' AND ')
    order='sort_text'
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
end
