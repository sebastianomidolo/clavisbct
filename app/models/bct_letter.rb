class BctLetter < ActiveRecord::Base
  attr_accessible :data, :mittente_id, :destinatario_id, :placefrom_id, :placeto_id, :fondo_id, :argomento, :nota,
  :nota_data, :descrizione_fisica, :updated_at, :updated_by

  self.table_name='letterebct.letters'

  belongs_to :updated_by, class_name: 'User', foreign_key: :updated_by
  belongs_to :mittente, :class_name=>'BctPerson'
  belongs_to :destinatario, :class_name=>'BctPerson'
  belongs_to :placefrom, :class_name=>'BctPlace'
  belongs_to :placeto, :class_name=>'BctPlace'
  belongs_to :bct_fondo, :foreign_key=>'fondo_id'

  before_save :check_record

  def ladata
    self.data.nil? ? self.nota_data : self.data
  end

  def pdflink
    "https://bctwww.comperio.it/lettereautografe/#{self.id}.pdf"
  end

  def pdf_filename
    config = Rails.configuration.database_configuration
    dir=config[Rails.env]["lettereautografe_basedir"]
    "#{File.join(dir, self.id.to_s)}.pdf"
  end

  def check_record
    if File.exists?(self.pdf_filename)
      self.pdf=true
    else
      self.pdf=false
    end
    true
  end

  def BctLetter.random_letter_with_abstract
    BctLetter.find_by_sql("SELECT * FROM #{BctLetter.table_name} WHERE length(argomento)>10 ORDER BY random() LIMIT 1").first
  end
  def BctLetter.random_letter_with_pdf
    BctLetter.find_by_sql("SELECT * FROM #{BctLetter.table_name} WHERE pdf ORDER BY random() LIMIT 1").first
  end

end
