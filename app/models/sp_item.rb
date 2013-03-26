class SpItem < ActiveRecord::Base
  self.table_name='sp.sp_items'

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
