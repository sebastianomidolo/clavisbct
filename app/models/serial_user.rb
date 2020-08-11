class SerialUser < ActiveRecord::Base
  self.primary_keys = :serial_list_id, :user_id

  belongs_to :serial_list  
end
