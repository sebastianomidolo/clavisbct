class SpItem < ActiveRecord::Base
  self.table_name='sp.sp_items'

  attr_accessible :bibliography_id, :item_id, :bibdescr, :updated_at, :section_number, :colldec, :sbn_bid, :created_at, :mainentry, :collciv, :sigle, :sortkey, :note

  belongs_to :sp_bibliography, :foreign_key=>'bibliography_id'

  def sp_section
    return nil if self.section_number.nil?
    SpSection.find_by_number_and_bibliography_id(self.section_number,self.bibliography_id)
  end

  def thesection
    return '' if self.section_number.nil?
    self.sp_section.title
  end

  def collocazioni
    self.collciv
  end
end
