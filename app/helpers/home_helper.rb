module HomeHelper

  def misc_periodici_musicale_in_ritardo
    sql=%Q{select op.excel_cell_id,ci.item_id,ci.title,
   ci.issue_status,lv.value_label as stato,
age(now()::date,ci.issue_arrival_date_expected) as ritardo,
ci.issue_arrival_date_expected as previsto
  from clavis.item ci
  join clavis.lookup_value lv on(ci.issue_status=lv.value_key)
  left join ordini_periodici_musicale op using(manifestation_id)
  where
   ci.owner_library_id=3
   and ci.issue_arrival_date_expected <= now()
   and value_language = 'it_IT' and value_class='ISSUESTATUS'
   and ci.issue_arrival_date_expected notnull
  and ci.issue_status in ('M','N','P')
--    and ci.issue_status in ('M')
--   order by age(now()::date,ci.issue_arrival_date_expected),ci.title,ci.issue_arrival_date_expected;
   order by ci.title,ci.issue_arrival_date_expected,age(now()::date,ci.issue_arrival_date_expected);}

    res=[]
    cnt=0
    ActiveRecord::Base.connection.execute(sql).each do |r|
      cnt+=1
      if r['excel_cell_id'].blank?
        lnk_excel= "#{cnt}."
        lnk_style=""
      else
        lnk_excel=link_to("#{cnt}.", excel_cell_path(r['excel_cell_id'].to_i))
        lnk_style={:class=>'success'}
      end
      res << content_tag(:tr,
                         content_tag(:td,lnk_excel,lnk_style) +
                         content_tag(:td, link_to(r['title'],
                                                  ClavisItem.clavis_url(r['item_id']))) +
                         content_tag(:td, r['previsto'].to_date) +
                         content_tag(:td, r['stato']) +
                         content_tag(:td, r['ritardo'], :class=>'danger'))
    end
    content_tag(:div, content_tag(:table, res.join.html_safe, :class=>'table table-striped'),
                :class=>'table-responsive')
  end

end
