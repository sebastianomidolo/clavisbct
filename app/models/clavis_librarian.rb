class ClavisLibrarian < ActiveRecord::Base
  self.table_name='clavis.librarian'
  self.primary_key = 'librarian_id'

  def iniziali
    status = self.activation_status=='1' ? 'attivo' : 'disattivato'
    "#{self.name[0]}#{self.lastname[0]} cat_level #{self.cat_level} - #{status}"
  end
end
