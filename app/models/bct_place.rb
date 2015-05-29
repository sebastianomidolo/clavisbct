class BctPlace < ActiveRecord::Base
  self.table_name='letterebct.places'
  has_many :letters_from, :class_name=>'BctLetter', :foreign_key=>'placefrom_id', :include=>:mittente
  has_many :letters_to, :class_name=>'BctLetter', :foreign_key=>'placeto_id', :include=>:destinatario
end
