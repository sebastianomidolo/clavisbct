class BctLetter < ActiveRecord::Base
  # attr_accessible :title, :body
  self.table_name='letterebct.letters'
  belongs_to :mittente, :class_name=>'BctPerson'
  belongs_to :destinatario, :class_name=>'BctPerson'
  belongs_to :placefrom, :class_name=>'BctPlace'
  belongs_to :placeto, :class_name=>'BctPlace'
  belongs_to :bct_fondo, :foreign_key=>'fondo_id'

  def ladata
    self.data.nil? ? self.nota_data : self.data
  end

  def BctLetter.random_letter_with_abstract
    BctLetter.find_by_sql("SELECT * FROM #{BctLetter.table_name} WHERE length(argomento)>10 ORDER BY random() LIMIT 1").first
  end

end
