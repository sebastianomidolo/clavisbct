class XhrRequest < ActiveRecord::Base
  attr_accessible :ip, :qs, :target, :timestamp
end
