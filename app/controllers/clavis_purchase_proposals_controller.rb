class ClavisPurchaseProposalsController < ApplicationController
  layout 'navbar'
  load_and_authorize_resource


  def index
    @clavis_purchase_proposal = ClavisPurchaseProposal.new(params[:clavis_purchase_proposal])
    @clavis_purchase_proposals=ClavisPurchaseProposal.list(@clavis_purchase_proposal,params)
  end

  def show
    @clavis_purchase_proposal = ClavisPurchaseProposal.find(params[:id])
  end

end
