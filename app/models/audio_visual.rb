class AudioVisual < ActiveRecord::Base
  self.table_name='bm_audiovisivi.t_volumi'
  self.primary_key = 'idvolume'

  attr_accessible :titolo, :collocazione, :autore, :interpreti, :tipologia

  has_many :attachments, :as => :attachable
  has_and_belongs_to_many(:clavis_manifestations, :join_table=>'av_manifestations',
                          :foreign_key=>'idvolume',
                          :association_foreign_key=>'manifestation_id');
end

