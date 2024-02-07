# coding: utf-8

class SbctEventStatus < ActiveRecord::Base
  self.table_name='sbct_acquisti.event_status'
  has_many :sbct_events, foreign_key:'event_status_id'

  def to_label
    self.event_status_label
  end

end
