# coding: utf-8
class SerialSubscription < ActiveRecord::Base
  self.primary_keys = :serial_title_id, :library_id
  attr_accessible :serial_title_id,:library_id,:prezzo,:note
  before_save :set_date_updated
  
  belongs_to :serial_title
  belongs_to :clavis_library, foreign_key: :library_id

  def set_date_updated
    self.date_updated=Time.now
  end

end

