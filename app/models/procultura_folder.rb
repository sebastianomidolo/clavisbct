class ProculturaFolder < ActiveRecord::Base
  self.table_name = 'procultura.folders'
  has_many :cards, :class_name=>'ProculturaCard', :foreign_key=>'folder_id'
end
