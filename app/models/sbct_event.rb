# coding: utf-8

class SbctEvent < ActiveRecord::Base
  self.table_name='sbct_acquisti.events'

  attr_accessible :event_status, :description, :name, :event_type_id, :event_status_id, :event_start, :event_end

  belongs_to :sbct_event_type, foreign_key:'event_type_id'
  belongs_to :sbct_event_status, foreign_key:'event_status_id'

  has_and_belongs_to_many(:sbct_titles, join_table:'sbct_acquisti.l_events_titles',
                          :foreign_key=>'event_id',
                          :association_foreign_key=>'id_titolo')

  validates :event_type_id, presence: true
  validates :name, presence: true

  before_save :add_timestamp

  def to_label
    self.name
  end

  def add_timestamp
    if self.date_created.nil?
      self.date_created = Time.now 
    else
      self.date_updated = Time.now
    end
  end

  def SbctEvent.label_select(params={},user=nil)
    sql=%Q{select e.event_id as key,e.name as label from sbct_acquisti.events e order by e.name;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = r['label']
      res << [label,r['key']]
    end
    res
  end
  
end
