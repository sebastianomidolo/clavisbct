class IssJournalsController < ApplicationController
  layout 'iss_journals'

  def index
    @iss_journals=IssJournal.where('pubblicato').order(:keytit)
  end
  def infopage
  end
  def show
    @iss_journal=IssJournal.find(params[:id])
    @iss_issues=@iss_journal.issues
  end

end
