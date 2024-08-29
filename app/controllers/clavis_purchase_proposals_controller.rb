class ClavisPurchaseProposalsController < ApplicationController
  layout 'sbct'
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle='Proposte di acquisto dei lettori'
    user_session[:pproposal_mode] = true
    @clavis_purchase_proposal = ClavisPurchaseProposal.new(params[:clavis_purchase_proposal])
    # render text:params[:clavis_purchase_proposal] and return
    if @clavis_purchase_proposal.title.to_i > 0
      @clavis_purchase_proposal = ClavisPurchaseProposal.find(@clavis_purchase_proposal.title.to_i)
    end
    @clavis_purchase_proposals=ClavisPurchaseProposal.tutte(@clavis_purchase_proposal,params)
    @clavis_patron = ClavisPatron.find(params[:patron_id]) if !params[:patron_id].blank?
    # render text:@clavis_purchase_proposals.size and return
  end

  def show
    @clavis_purchase_proposal = ClavisPurchaseProposal.find(params[:id])
  end
  def edit
  end
  def update
    if @clavis_purchase_proposal.aggiorna_tabella(params[:clavis_purchase_proposal])
      flash[:notice] = "Modifiche salvate"
      respond_with(@clavis_purchase_proposal)
    else
      flash[:notice] = "Errore nel salvataggio"
      render :action => "edit"
    end
  end
  def sql_shelf_update
    sql=ClavisPurchaseProposal.update_shelf(33942, '60 days')
    send_data sql, type: Mime::TEXT, disposition: "attachment; filename=sql_shelf_update.sql"
    # render text:"<pre>#{sql}</pre>"
  end
  def sql_cpp_update
    sql=ClavisPurchaseProposal.update_cpp
    send_data sql, type: Mime::TEXT, disposition: "attachment; filename=sql_cpp_update.sql"
  end

end
