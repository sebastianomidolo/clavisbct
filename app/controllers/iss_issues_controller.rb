class IssIssuesController < ApplicationController
  layout 'iss_journals'

  def show
    @iss_issue=IssIssue.find(params[:id])
  end

  def toc
    @iss_issue=IssIssue.find(params[:id])
  end

  def cover_image
    issue=IssIssue.find(params[:id])
    send_data(issue.copertina_jpg, filename:"issue#{issue.id}.jpg",:disposition=>'inline',:type=>'image/jpeg')
  end

end
