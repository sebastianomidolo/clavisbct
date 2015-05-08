# lastmod 20 febbraio 2013

class ClavisIssue < ActiveRecord::Base
  self.table_name='clavis.issue'
  self.primary_key = 'issue_id'

  attr_accessible :manifestation_id, :issue_id, :issue_volume

  belongs_to :clavis_manifestation, :foreign_key=>:issue_id

  def ClavisIssue.lastin(params)
    library_id=params[:library_id].to_i
    limit = params[:limit].blank? ? "LIMIT 10" : "LIMIT #{params[:limit].to_i}"
    sql=%Q{SELECT i.issue_id,i.issue_number,cm.title,cm.manifestation_id,
     ci.issue_arrival_date,ci.collocation,ci.issue_status,ci.issue_arrival_date,
      ca.attachment_id,
      array_to_string((xpath('//d856/su/text()',cm.unimarc::xml)),'%%%') as er_resource_urls,
      array_to_string((xpath('//d856/sz/text()',cm.unimarc::xml)),'%%%') as er_resource_notes
     FROM clavis.issue i JOIN clavis.item ci USING(issue_id,manifestation_id)
        JOIN clavis.manifestation cm USING(manifestation_id)
        LEFT JOIN clavis.attachment ca ON(ca.object_type='Manifestation' AND ca.object_id=cm.manifestation_id)
      WHERE ci.owner_library_id=#{library_id} AND issue_status IN ('A','U')
         AND ci.issue_arrival_date IS NOT NULL
      ORDER BY ci.issue_arrival_date DESC, cm.sort_text #{limit};
   }
    ClavisIssue.find_by_sql(sql)
  end

end
