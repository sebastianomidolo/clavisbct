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

  def collocazione_magazzino
    self.clavis_item.collocazione
  end
  def collocazione_scaffale_aperto
    sql="SELECT * FROM ricollocazioni WHERE item_id = #{self.id}"
    r=OpenShelfItem.connection.execute(sql).first
    if self.os_section=='CCNC'
      x="#{r['vedetta']}".strip
    else
      x=r['dewey_collocation']
    end
    I18n.transliterate(x)
  end

  def OpenShelfItem.sections
    sql=%Q{select value_key as key,value_label as label,count(ci.item_id) from clavis.library_value lv left join clavis.item ci on(value_key=ci.section) where value_class = 'ITEMSECTION' and value_library_id=2 and value_key in ('CCVT','CCNC','CCTL','CCPT','SAP') group by value_key,value_label order by value_key}
    self.connection.execute(sql).to_a.collect{|x| [x['label'] + " [ricollocati: #{x['count']}]",x['key']] }
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
    OpenShelfItem.connection.execute(sql).to_a
  end

  def OpenShelfItem.lista_da_magazzino(dest_section,page,per_page,verb,escludi_in_prestito,text_filter,escludi_ricollocati)
    if ['CCNC','CCTP'].include?(dest_section)
      order_by = 'collocazione_scaffale_aperto,item_id'
    else
      order_by = 'espandi_dewey(collocazione_scaffale_aperto),item_id'
    end
    extra_cond = []
    extra_cond << "loan_status='A' AND item_status='F' AND loan_class='B'" if !escludi_in_prestito.blank?
    extra_cond << "section!=os_section" if !escludi_ricollocati.blank?
    if !text_filter.blank?
      ts=OpenShelfItem.connection.quote_string(text_filter.split.join(' & '))
      extra_cond << "to_tsvector('simple', titolo) @@ to_tsquery('simple', '#{ts}')"
    end
    extra_cond = extra_cond.join(" AND ")
    extra_cond = "AND #{extra_cond}" if extra_cond!=''
    if verb=='estrai'
      subselect=%Q{select * from clavis.view_estrazione_da_magazzino
       where os_section = #{self.connection.quote(dest_section)} #{extra_cond}
        order by #{order_by} limit #{per_page} offset #{(page-1)*per_page}}
      sql=%Q{select * from (#{subselect}) as t1 order by espandi_collocazione(collocazione_magazzino)}
    else
      sql=%Q{select * from clavis.view_estrazione_da_magazzino
       where os_section = #{self.connection.quote(dest_section)} #{extra_cond}
        order by #{order_by} limit #{per_page} offset #{(page-1)*per_page}}
    end
    # puts sql
    OpenShelfItem.connection.execute(sql).to_a
  end

  def OpenShelfItem.conta(os_section=nil,escludi_in_prestito,text_filter,escludi_ricollocati)
    return self.count if os_section.blank?
    extra_cond=''
    if !text_filter.blank?
      ts=OpenShelfItem.connection.quote_string(text_filter.split.join(' & '))
      extra_cond << " AND to_tsvector('simple', titolo) @@ to_tsquery('simple', '#{ts}')"
    end
    extra_cond << " AND loan_status='A' AND item_status='F' AND loan_class='B'" if !escludi_in_prestito.blank?
    extra_cond << " AND os_section!=section" if !escludi_ricollocati.blank?
    sql=%Q{SELECT count(*) FROM clavis.view_estrazione_da_magazzino
         WHERE os_section=#{self.connection.quote(os_section)} #{extra_cond}}
    OpenShelfItem.connection.execute(sql).first['count'].to_i
  end
  def OpenShelfItem.label(os_section=nil)
    return '' if os_section.blank?
    r=self.connection.execute("select value_label from clavis.library_value where value_class = 'ITEMSECTION' and value_library_id=2 and value_key = #{self.connection.quote(os_section)}").first
    r.nil? ? '' : r['value_label']
  end


end
