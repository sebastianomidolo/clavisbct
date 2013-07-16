class TalkingBook < ActiveRecord::Base
  self.table_name='libroparlato.catalogo'
  self.primary_key = 'id'
  has_one :clavis_item, :foreign_key=>'collocation', :primary_key=>'n'
  has_many :attachments, :as => :attachable

  def digitalized
    self.digitalizzato.nil? ? false : true
  end

  def TalkingBook.filename2colloc(fname)
    regexp_collocazione = /(NA|NB|NT|MP) +((\d+)[ -]|(\d+$))/
    regexp_collocazione =~ fname
    if $1=='MP'
      p="CD MP"
    else
      p=$1
    end
    num=$2.to_i
    "#{p} #{num}"
  end
end
