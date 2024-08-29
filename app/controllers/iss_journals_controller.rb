class IssJournalsController < ApplicationController
  # layout 'iss_journals-orig'
  layout 'iss_journals'

  def index
    @pagetitle='Riviste digitalizzate BCT'
    @iss_journals=IssJournal.where('pubblicato').order(:keytit)
  end
  def infopage
  end
  def show
    @iss_journal=IssJournal.find(params[:id])
    @cm = ClavisManifestation.find_by_bid(@iss_journal.bid)
    @iss_issues=@iss_journal.issues
    @pagetitle="#{@iss_journal.title} - Riviste digitalizzate BCT"
  end

end
