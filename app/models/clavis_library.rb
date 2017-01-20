class ClavisLibrary < ActiveRecord::Base
  self.table_name='clavis.library'
  self.primary_key = 'library_id'

  has_many :owned_items, class_name: 'ClavisItem', foreign_key: 'owner_library_id'
  has_many :ordini, foreign_key: 'library_id'
  has_many :timetables, class_name: 'ClavisLibraryTimetable', foreign_key: 'library_id'
  has_many :containers, foreign_key: 'library_id'

  def to_label
    self.label[0..40]
  end
  def nice_description
    self.description[5..100]
  end

  def clavis_url
    ClavisLibrary.clavis_url(self.id)
  end

  def week_timetable
    date  = Date.parse('Monday')
    self.timetables.where("timetable_day>='#{date.strftime('%F')}'").limit(7).order('timetable_day')
  end

  def ClavisLibrary.clavis_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Library.LibraryViewPage&id=#{id}"
  end

  def ClavisLibrary.library_select
    sql=%Q{select library_id as key,label from clavis.library
      where library_internal='1' order by label}
    self.connection.execute(sql).collect {|i| [i['key'],i['label']]}
  end
  
end
