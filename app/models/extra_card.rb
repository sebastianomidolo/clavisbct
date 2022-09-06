# coding: utf-8
class ExtraCard < ActiveRecord::Base
  attr_accessible :titolo, :collocazione, :inventory_serie_id, :inventory_number, :deleted,\
                  :home_library_id, :note_interne, :login, :mancante, :created_at, :created_by, :updated_by,\
                  :updated_at
                                                                                                  
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

  def ExtraCard.load_from_excel(filename,basecoll,user)
    sys_user = User.find_by_email('topografico');
    data = Roo::Spreadsheet.open(filename)
    headers = [:collocazione,:titolo,:inventory_serie_id,:inventory_number,:note_interne]
    res = []
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header
      item = Hash[[headers, row].transpose]
      catena = item[:collocazione].to_i
      if catena == 0
        res << "Anomalia colonna 1, non sembra un numero di catena: #{item[:collocazione]}"
        next
      end
      nd = {
        home_library_id:2,
        collocazione:"#{basecoll}.#{item[:collocazione].to_i}",
        titolo:item[:titolo],
        inventory_serie_id:item[:inventory_serie_id],
        inventory_number:item[:inventory_number],
        note_interne:item[:note_interne],
        created_at:Time.now,
        updated_at:Time.now,
        created_by:sys_user,
        updated_by:user,
      }
      ec = ExtraCard.new(nd)
      r = ExtraCard.find_by_home_library_id_and_collocazione(ec.home_library_id, ec.collocazione)
      if r.nil?
        res << "<b>#{ec.collocazione} non presente in ClavisBct, effettuo inserimento (titolo: #{ec.titolo})</b>"
        ec.save
      else
        res << "==> \"#{ec.collocazione}\" già presente per titolo \"#{ec.titolo}\" (serie-inv: #{ec.inventory_serie_id}-#{ec.inventory_number})"
      end
    end
    res.join("\n")
  end

end
