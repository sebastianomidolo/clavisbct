class ProculturaCard < ActiveRecord::Base
  self.table_name = 'procultura.cards'
  belongs_to :folder, :class_name=>'ProculturaFolder'

end
