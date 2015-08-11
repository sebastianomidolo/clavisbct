class OpenShelfItem < ActiveRecord::Base
  self.primary_key = 'item_id'
  attr_accessible :item_id
  belongs_to :clavis_item, foreign_key:'item_id'

  def section
    sql=%Q{SELECT lv.value_label AS s FROM clavis.item ci, clavis.library_value lv
            WHERE ci.item_id=#{self.id} AND ci.owner_library_id=lv.value_library_id
             AND lv.value_key='#{self.os_section}'}
    OpenShelfItem.connection.execute(sql).first['s']
  end

  def OpenShelfItem.sections
    self.connection.execute("select value_key as key,value_label as label from clavis.library_value where value_class = 'ITEMSECTION' and value_library_id=2 and value_key in ('VT','NC','TL','BB')").to_a.collect{|x| [x['label'],x['key']] }
  end

  def OpenShelfItem.dewey_list(dest_section=nil)
    cond = []
    cond << "o.os_section=#{self.connection.quote(dest_section)}" if !dest_section.blank?
    wherecond = cond.size==0 ? '' : "WHERE #{cond.join(' AND ')}"
    sql=%Q{SELECT r.class_id,ca.class_code,ca.full_text AS dewey,count(*) FROM open_shelf_items o
      join clavis.item ci using(item_id) join clavis.manifestation cm using(manifestation_id)
      join ricollocazioni r using(item_id)
      join clavis.authority ca on(ca.authority_id=r.class_id)
      #{wherecond}
      GROUP by r.class_id,ca.class_code,ca.full_text order by espandi_dewey(ca.class_code);}
    puts sql
    OpenShelfItem.connection.execute(sql).to_a
  end

  def OpenShelfItem.openshelf_list(dest_section)
    criterio = dest_section=='NC' ? 'r.vedetta' : 'r.dewey_collocation'
    sql=%Q{SELECT ci.manifestation_id,ci.title,#{criterio} as "new_collocation",
         compact_collocation(ci."section",ci.collocation,
          ci.specification,ci.sequence1,ci.sequence2) as old_collocation
        FROM open_shelf_items os JOIN clavis.item ci USING(item_id)
           JOIN ricollocazioni r USING(item_id)
        WHERE os.os_section=#{self.connection.quote(dest_section)}
         ORDER BY #{criterio};}
    puts sql
    OpenShelfItem.find_by_sql(sql)
  end

  def OpenShelfItem.conta(os_section=nil)
    return self.count if os_section.blank?
    self.count(conditions:"os_section=#{self.connection.quote(os_section)}")
  end
  def OpenShelfItem.label(os_section=nil)
    return '' if os_section.blank?
    r=self.connection.execute("select value_label from clavis.library_value where value_class = 'ITEMSECTION' and value_library_id=2 and value_key = #{self.connection.quote(os_section)}").first
    r.nil? ? '' : r['value_label']
  end


end
