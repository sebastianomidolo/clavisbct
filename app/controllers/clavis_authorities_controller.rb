# lastmod 21 dicembre 2012
# lastmod 19 dicembre 2012

class ClavisAuthoritiesController < ApplicationController
  def info
    headers['Access-Control-Allow-Origin'] = "*"
    sql=%Q{SELECT r.value_label as rectype,t.value_label as authtype,
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
end
