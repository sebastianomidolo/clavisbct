class SbctLClavisPurchaseProposalTitle < ActiveRecord::Base
  self.table_name = 'sbct_acquisti.l_clavis_purchase_proposals_titles'
  self.primary_keys = [:proposal_id,:id_titolo]

  belongs_to :sbct_title, :foreign_key=>'id_titolo'
  belongs_to :clavis_purchase_proposal, :foreign_key=>'proposal_id'

end

