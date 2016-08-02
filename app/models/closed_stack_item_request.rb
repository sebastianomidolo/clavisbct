class ClosedStackItemRequest < ActiveRecord::Base
  attr_accessible :dng_session_id, :item_id, :patron_id, :request_time
end
