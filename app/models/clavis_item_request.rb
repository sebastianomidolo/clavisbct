# -*- coding: utf-8 -*-

class ClavisItemRequest < ActiveRecord::Base
  self.table_name = 'clavis.item_request'
  self.primary_key = 'request_id'

  def self.indice(params)
    if params[:request_date].blank?
      sql=%Q{SELECT request_date::char(10),count(*) from clavis.item_request where item_id notnull and request_status='A' group by request_date::char(10)
                order by request_date::char(10) desc}
    else
      sql=%Q{SELECT cl.library_id,cl.label,count(*) from clavis.item_request ir
                JOIN clavis.library cl on(cl.library_id=ir.delivery_library_id)
            where ir.request_status='A' and ir.item_id notnull and ir.request_date::char(10)=#{self.connection.quote(params[:request_date])}
          group by cl.label,cl.library_id
          order by cl.label,cl.library_id}
    end
    self.find_by_sql(sql)
  end
  def self.item_ids(library_id,request_date)
    sql=%Q{SELECT item_id FROM clavis.item_request WHERE item_id notnull AND request_status='A'
                    AND delivery_library_id=#{self.connection.quote(library_id.to_i)}
                    AND request_date::char(10)=#{self.connection.quote(request_date)}}
    self.connection.execute(sql).to_a.collect{|r| r['item_id']}.join('+')
  end
end
