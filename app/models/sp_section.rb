class SpSection < ActiveRecord::Base
  self.table_name='sp.sp_sections'

  belongs_to :sp_bibliography, :foreign_key=>'bibliography_id'

  def sp_items
    sql=%Q{SELECT * FROM sp.sp_items WHERE bibliography_id = '#{self.bibliography_id}' and section_number=#{self.number} order by sortkey}
    SpItem.find_by_sql(sql)
  end

  def sp_sections
    sql=%Q{SELECT * FROM sp.sp_sections WHERE bibliography_id = '#{self.bibliography_id}' and parent=#{self.number} order by sortkey}
    SpSection.find_by_sql(sql)
  end


end
