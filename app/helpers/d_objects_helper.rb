module DObjectsHelper
  def d_object_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      v = (k=='bfilesize') ? "#{number_to_human_size(record[k])} (#{record[k]})" : record[k]
      res << content_tag(:tr, content_tag(:td, k) +
                         content_tag(:td, v))
    end
    res=content_tag(:table, res.join.html_safe)
  end
  def d_objects_summary
    sql="select mime_type,count(*),sum(bfilesize) as bfilesize from d_objects group by mime_type order by lower(mime_type)"
    pg=ActiveRecord::Base.connection.execute(sql)
    res=[]
    pg.each do |r|
      lnk=d_objects_path(:mime_type=>r['mime_type'])
      n=number_to_human_size(r['bfilesize'])
      res << content_tag(:tr, content_tag(:td, link_to(r['mime_type'], lnk)) +
                         content_tag(:td, r['count']) +
                         content_tag(:td, n))
    end
    content_tag(:table, res.join.html_safe)
  end
end
