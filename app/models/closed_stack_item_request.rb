class ClosedStackItemRequest < ActiveRecord::Base
  attr_accessible :dng_session_id, :item_id, :patron_id, :request_time

  belongs_to :clavis_item, foreign_key:'item_id'

  def ClosedStackItemRequest.list
    sql=%Q{select ir.*,ci.title,cl.*,cp.lastname from closed_stack_item_requests ir join clavis.item ci using(item_id)
        join clavis.patron cp on(cp.patron_id=ir.patron_id)
        join clavis.centrale_locations cl using(item_id) order by cl.piano, espandi_collocazione(cl.collocazione)}
    ClosedStackItemRequest.connection.execute(sql).to_a
  end
    

end
