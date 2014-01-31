class AudioVisual < ActiveRecord::Base
  self.table_name='bm_audiovisivi.t_volumi'
  self.primary_key = 'idvolume'

  attr_accessible :titolo, :collocazione, :autore, :interpreti, :tipologia, :editore

  has_many :attachments, :as => :attachable
  has_and_belongs_to_many(:clavis_manifestations, :join_table=>'av_manifestations',
                          :foreign_key=>'idvolume',
                          :association_foreign_key=>'manifestation_id');
  belongs_to :clavis_manifestation, :foreign_key=>'manifestation_id'

  def naxos_cid
    # E' molto difficile ricavare l'identificativo su Naxos a partire dagli elementi che abbiamo
    # a disposizione, questa e' una prova che non e' detto possa essere sviluppata ulteriormente
    return nil if self.editore.blank? or self.numero_editoriale.blank?
    key=self.numero_editoriale
    key.gsub!(' ','')
    labels={
      'bis' => 'BIS',
      'harmonia mundi' => 'HMC'
    }
    sigla=''
    labels.each_pair do |k,v|
      if self.editore.downcase==k
        sigla=v and break
      end
    end
    key.gsub!(sigla,'')
    return nil if sigla.blank?
    "#{sigla}-#{key}"
  end

  def naxos_link
    return nil if self.naxos_cid.blank?
    "http://naxosml.medialibrary.it/catalogue/item.asp?cid=#{self.naxos_cid}"
  end
end

