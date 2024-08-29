class Request < ActiveRecord::Base
  self.table_name='stats.requests'
  attr_accessible :utente, :collocazione, :inventario, :titolo, :description, :id, :library_id, :patron_id, :request_date

  belongs_to :clavis_patron, foreign_key:'patron_id'
  belongs_to :clavis_library, foreign_key:'library_id'

  def to_label
    if self.patron_id.nil?
      "numero #{self.id} - biblioteca #{self.clavis_library.siglabct}"
    else
      "numero #{self.id} #{self.clavis_patron.to_label} - biblioteca #{self.clavis_library.siglabct}"
    end
  end

end
