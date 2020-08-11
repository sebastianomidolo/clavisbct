class TalkingBookReader < ActiveRecord::Base
  self.table_name='libroparlato.volontari'
  attr_accessible :cognome, :nome, :telefono, :attivo
  has_many :talking_books, foreign_key:'volontario_id'

  def to_label
    "#{cognome}, #{nome}#{attivo? ? '' : ' (non attivo)'}"
  end
end

