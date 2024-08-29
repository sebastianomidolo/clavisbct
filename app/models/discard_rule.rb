class DiscardRule < ActiveRecord::Base
  attr_accessible :classe_from, :classe_to, :descrizione, :edition_age, :anni_da_ultimo_prestito, :pubblico, :smusi

  validates :classe_from, presence: true
  before_save :removeblanks

  def removeblanks
    self.classe_from=nil if self.classe_from.blank?
    if self.classe_to.blank?
      self.classe_to=self.classe_from
    end
    # self.genere=nil if self.genere.blank?
    self.pubblico=nil if self.pubblico.blank?
  end
end

