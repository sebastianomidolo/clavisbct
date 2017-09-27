class ExtraCard < ActiveRecord::Base
  attr_accessible :titolo, :collocazione, :inventory_serie_id, :inventory_number, :deleted,\
                  :home_library_id, :note_interne, :login, :mancante
  self.table_name='topografico_non_in_clavis'

  belongs_to :created_by, class_name: 'User', foreign_key: :created_by
  belongs_to :updated_by, class_name: 'User', foreign_key: :updated_by

  validates :titolo, :collocazione, presence: true

  before_save :check_record
  after_save :verifica_piano_centrale

  def clavis_item
    ClavisItem.find_by_custom_field3_and_owner_library_id(self.id.to_s,-1)
  end

  def verifica_piano_centrale
    ci=self.clavis_item
    return if ci.nil?
    ci.piano_centrale
  end

  def serieinv
    "#{self.inventory_serie_id}-#{inventory_number}"
  end
  def check_record
    self.deleted=false if self.deleted.nil?
  end

end
