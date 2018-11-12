class ClosedStackItemRequest < ActiveRecord::Base
  attr_accessible :dng_session_id, :item_id, :patron_id, :request_time

  belongs_to :clavis_item, foreign_key:'item_id'

  def ClosedStackItemRequest.assign_daily_counter(patron)
    daily_counter = DailyCounter.create
    ids=self.list(patron.id).collect{|r| r.id}.join(',')
    return nil if ids.blank?
    self.connection.execute %Q{UPDATE closed_stack_item_requests SET daily_counter = #{daily_counter.id} where id in(#{ids})}
    daily_counter
  end

  def ClosedStackItemRequest.richieste_magazzino
    sql=%Q{select ir.id,cl.piano,cc.collocazione,cp.lastname,ir.daily_counter,ci.title
       from closed_stack_item_requests ir 
         join clavis.patron cp using(patron_id)
         join clavis.item ci using(item_id)
           left join clavis.collocazioni cc using(item_id) left join clavis.centrale_locations cl using(item_id)
          where true and daily_counter is not null and not printed
	      and request_time > CURRENT_DATE order by cl.piano,espandi_collocazione(cc.collocazione)}
    self.connection.execute(sql).to_a
  end

  def ClosedStackItemRequest.list(patron_id=nil,pending=true,printed=false,today=true)
    sql=%Q{select ir.*,ci.title,cl.piano,cl.collocazione,cp.lastname from closed_stack_item_requests ir join clavis.item ci using(item_id)
        join clavis.patron cp on(cp.patron_id=ir.patron_id)
        join clavis.centrale_locations cl using(item_id) where #{self.sql_and_conditions_for_list(patron_id,pending,printed,today)}
         order by cl.piano, espandi_collocazione(cl.collocazione)}
    ClosedStackItemRequest.find_by_sql(sql)
  end

  def ClosedStackItemRequest.sql_and_conditions_for_list(patron_id=nil,pending=true,printed=false,today=true)
    cond = []
    cond << (patron_id.blank? ? 'true' : "cp.patron_id=#{self.connection.quote(patron_id)}")
    cond << (pending ? 'daily_counter is null' : 'daily_counter is not null')
    cond << (printed ? 'printed' : 'not printed') if printed!=:both
    cond << 'request_time > CURRENT_DATE' if today
    cond.join(' and ')
  end

  def ClosedStackItemRequest.mark_as_printed(records)
    ids=records.collect{|x| x['id']}.join(',')
    return if ids.blank?
    sql=%Q{update closed_stack_item_requests set printed=true where id in(#{ids})}
    self.connection.execute(sql)
  end

  def ClosedStackItemRequest.list_pdf(records)
    inputdata=[]
    inputdata << [records]
    lp=LatexPrint::PDF.new('closed_stack_items_request', inputdata, false)
    lp.makepdf
  end
  
  def ClosedStackItemRequest.patrons(pending=:true,printed=:false,today=:true)
    cond = []
    cond << 'request_time > CURRENT_DATE' if today
    cond << "printed is #{printed}"
    cond << "daily_counter is #{(pending == true ? 'null' : 'not null')}"
    cond = cond.size==0 ? '' : "WHERE #{cond.join(' AND ')}"
    self.connection.execute(%Q{select cp.name,cp.lastname,patron_id,barcode,count(*)
      from closed_stack_item_requests r join clavis.patron cp using(patron_id)
       #{cond}
       group by cp.name,cp.lastname,patron_id,barcode order by lower(cp.lastname),lower(cp.name)}).to_a
  end

  def ClosedStackItemRequest.random_insert
    self.connection.execute %Q{
     insert into closed_stack_item_requests(dng_session_id,patron_id,item_id)
      (select -1,
        (select patron_id from clavis.patron where opac_enable = '1'
          and last_seen > '2018-01-01' and patron_status='A' order by random() limit 1
         ), item_id from clavis.item where home_library_id = 2 and
      loan_status='A' and loan_class='B' and item_media='F' and section !=
       'BCTA' AND section ~ 'BCT' and manifestation_id != 0 and
       item_status='F' and item_media='F' and opac_visible = 1 order by random() limit 8)}
  end
end
