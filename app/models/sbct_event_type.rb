# coding: utf-8

class SbctEventType < ActiveRecord::Base
  self.table_name='sbct_acquisti.event_types'

  attr_accessible :event_type_id, :label

  has_many :sbct_events, foreign_key:'event_type_id'

  def to_label
    self.label
  end
end
