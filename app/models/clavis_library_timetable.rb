class ClavisLibraryTimetable < ActiveRecord::Base
  self.table_name='clavis.library_timetable'
  self.primary_key = 'timetable_id'
  belongs_to :clavis_library, foreign_key:'library_id'
end
