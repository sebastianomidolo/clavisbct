class ClavisLAuthorityManifestation < ActiveRecord::Base
  self.table_name = 'clavis.l_authority_manifestation'

  belongs_to :clavis_manifestation, :foreign_key=>'manifestation_id'
  belongs_to :clavis_authority, :foreign_key=>'authority_id'
  belongs_to :subject, :primary_key=>'clavis_authority_id', :foreign_key=>'authority_id'

end

