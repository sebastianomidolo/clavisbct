class SpBibliography < ActiveRecord::Base
  self.table_name='sp.sp_bibliographies'

  has_many :sp_sections, :foreign_key=>'bibliography_id'
  has_many :sp_items, :foreign_key=>'bibliography_id'
end
