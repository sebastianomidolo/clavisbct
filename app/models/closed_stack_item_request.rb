# coding: utf-8
class ClosedStackItemRequest < ActiveRecord::Base
  attr_accessible :dng_session_id, :item_id, :patron_id, :request_time, :created_by

  belongs_to :clavis_item, foreign_key:'item_id'

  def ClosedStackItemRequest.assign_daily_counter(patron, confirmed_by)
    ids=self.list(patron.id).collect{|r| r.id}.join(',')
    return nil if ids.blank?

    ticket=patron.csir_tickets(nil).first
    if !ticket.nil?
      dc = ticket
    else
      dc = DailyCounter.last.id
      DailyCounter.create
    end
    sql=%Q{UPDATE closed_stack_item_requests SET confirmed_by=#{confirmed_by}, daily_counter = #{dc},confirm_time=now() at time zone 'utc' where id in(#{ids})}
    rc=self.connection.execute(sql)
    self.connection.clear_query_cache
    dc
  end

  def ClosedStackItemRequest.oggi
    sql=%Q{select ir.id, regexp_replace(cl.piano,'^0. ','') as piano,cc.collocazione,cp.lastname,cp.name,cp.patron_id,ir.daily_counter,
       ir.request_time, substr(ci.title,1,40) as title, ci.inventory_serie_id || '-' || ci. inventory_number as serieinv, ci.item_id
          from closed_stack_item_requests ir
          join clavis.patron cp using(patron_id)
          join clavis.item ci using(item_id)
          left join clavis.collocazioni cc using(item_id) left join clavis.centrale_locations cl using(item_id)
          where request_time > CURRENT_DATE order by ir.id desc;}
    ClosedStackItemRequest.find_by_sql(sql)
  end

  def ClosedStackItemRequest.richieste_magazzino(patron_id=nil,reprint=false,archived=false,order=:per_piano)
    wherepatron = patron_id.nil? ? '' : "AND ir.patron_id=#{patron_id}"
    and_condition = reprint==true ? "not archived" : "not printed"
    order = order == :per_piano ? 'cl.piano desc,espandi_collocazione(cc.collocazione)' : 'espandi_collocazione(cc.collocazione)'
    sql=%Q{select ir.id, regexp_replace(cl.piano,'^0. ','') as piano,cc.collocazione,cp.lastname,cp.patron_id,ir.daily_counter,
         ci.title, ci.inventory_serie_id || '-' || ci. inventory_number as serieinv
       from closed_stack_item_requests ir 
         join clavis.patron cp using(patron_id)
         join clavis.item ci using(item_id)
           left join clavis.collocazioni cc using(item_id) left join clavis.centrale_locations cl using(item_id)
          where true and daily_counter is not null and #{and_condition} #{wherepatron}
	      and request_time > CURRENT_DATE order by #{order}}
    self.connection.execute(sql).to_a
  end

  def ClosedStackItemRequest.list(patron_id=nil,pending=true,printed=false,today=true,archived=false,reprint=false,order=:per_piano)
    if order.class==String
      order = order
    else
      order = order == :per_piano ? 'cl.piano desc,espandi_collocazione(cl.collocazione)' : 'espandi_collocazione(cl.collocazione)'
    end
    sql=%Q{select ir.*,ci.title,regexp_replace(cl.piano,'^0. ','') as piano,cl.collocazione,cp.lastname, 
            ci.inventory_serie_id || '-' || ci. inventory_number as serieinv
       from closed_stack_item_requests ir join clavis.item ci using(item_id)
        join clavis.patron cp on(cp.patron_id=ir.patron_id)
        join clavis.centrale_locations cl using(item_id) where
           #{self.sql_and_conditions_for_list(patron_id,pending,printed,today,archived,reprint)} order by #{order}}
    ClosedStackItemRequest.find_by_sql(sql)
  end

  def ClosedStackItemRequest.sql_and_conditions_for_list(patron_id=nil,pending=true,printed=false,today=true,archived=false,reprint=false)
    cond = []
    cond << (patron_id.blank? ? 'true' : "cp.patron_id=#{self.connection.quote(patron_id)}")
    cond << (pending ? 'daily_counter is null' : 'daily_counter is not null') if !pending.nil?
    if archived==false
      if reprint == false
        cond << (printed ? 'printed' : 'not printed') if !printed.nil?
      end
      cond << 'not archived'
    else
      cond << 'archived' if !archived.nil?
    end
    cond << 'request_time > CURRENT_DATE' if today
    cond.join(' and ')
  end

  def ClosedStackItemRequest.mark_as_printed(records)
    ids=records.collect{|x| x['id']}.join(',')
    return if ids.blank?
    sql=%Q{update closed_stack_item_requests set printed=true,print_time=now() at time zone 'utc' where id in(#{ids})}
    self.connection.execute(sql)
  end

  def ClosedStackItemRequest.list_pdf(records,patron_id=nil,reprint=false)
    inputdata=[]
    inputdata << [records]
    inputdata << patron_id
    inputdata << reprint
    lp=LatexPrint::PDF.new('closed_stack_items_request', inputdata, false)
    lp.makepdf
  end

  def ClosedStackItemRequest.logfile(params,patron=nil)
    patron_id = patron.class==ClavisPatron ? patron.id : patron
    where=patron_id.blank? ? '' : "where ir.patron_id=#{patron_id}"
    sql=%Q{select ir.patron_id,ir.id as request_id,s.client_ip,s.login_time,s.id as dng_session_id,
   ir.request_time,ir.confirm_time,ir.print_time,trim(ci.title) as title,ir.item_id,
   cp.lastname as patron_lastname,cp.name as patron_name,cp.barcode as patron_barcode,
   u1.email as u_created_by,
   u1.id    as u_created_by_id,
   trim(cl1.name) || ' ' || trim(cl1.lastname) as l_created_by,
   cl1.librarian_id as l_created_by_id,
   u2.email as u_confirmed_by,
   u2.id    as u_confirmed_by_id,
   trim(cl2.name) || ' ' || trim(cl2.lastname) as l_confirmed_by,
   cl2.librarian_id as l_confirmed_by_id
   from
       closed_stack_item_requests ir join
       clavis.patron cp using(patron_id) join
       clavis.item ci using(item_id) left join
       dng_sessions s on(s.id=ir.dng_session_id) left join
       users u1 on(u1.id=ir.created_by) left join
       users u2 on(u2.id=ir.confirmed_by) left join
       clavis.librarian cl1 on(cl1.username=u1.email) left join
       clavis.librarian cl2 on(cl2.username=u2.email)
    #{where} order by ir.id desc}
    self.paginate_by_sql(sql, :per_page=>200, :page=>params[:page])
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
    num_items=((rand() * 6)+1).to_i
    self.connection.execute %Q{
     insert into closed_stack_item_requests(dng_session_id,patron_id,item_id,request_time)
      (select -1,
        (select patron_id from clavis.patron where opac_enable = '1'
          and last_seen > '2018-01-01' and patron_status='A' order by random() limit 1
         ), item_id, now() at time zone 'utc' from clavis.item where home_library_id = 2 and
      loan_status='A' and loan_class='B' and item_media='F' and section !=
       'BCTA' AND section ~ 'BCT' and manifestation_id != 0 and
       item_status='F' and item_media='F' and opac_visible = 1 order by random() limit #{num_items})}
  end
end
