class BibSection < ActiveRecord::Base
  attr_accessible :name
  has_many :collocazioni, class_name:'SchemaCollocazioniCentrale'
end
