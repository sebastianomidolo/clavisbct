class SbctLEventTitle < ActiveRecord::Base
  self.table_name = 'sbct_acquisti.l_events_titles'
  self.primary_keys = [:event_id,:id_titolo]

  attr_accessible :numcopie, :notes, :event_id, :id_titolo

  belongs_to :sbct_title, :foreign_key=>'id_titolo'
  belongs_to :sbct_event, :foreign_key=>'event_id'

end

