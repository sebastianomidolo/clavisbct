class ClavisPurchaseProposalsController < ApplicationController
  layout 'navbar'
  load_and_authorize_resource


  def index
    @pagetitle='Proposte di acquisto dei lettori'

    @clavis_purchase_proposal = ClavisPurchaseProposal.new(params[:clavis_purchase_proposal])
    @clavis_purchase_proposals=ClavisPurchaseProposal.list(@clavis_purchase_proposal,params)
    @clavis_patron = ClavisPatron.find(params[:patron_id]) if !params[:patron_id].blank?
    # render text:@clavis_purchase_proposals.size and return
  end

  def show
    @clavis_purchase_proposal = ClavisPurchaseProposal.find(params[:id])
  end

end
