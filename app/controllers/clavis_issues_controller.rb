# lastmod 13 dicembre 2012

class ClavisIssuesController < ApplicationController
  # GET /clavis_issues
  # GET /clavis_issues.json
  def index
    @clavis_issues = ClavisIssue.all(:limit=>10)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @clavis_issues }
    end
  end

  # GET /clavis_issues/1
  # GET /clavis_issues/1.json
  def show
    headers['Access-Control-Allow-Origin'] = "*"

    if params[:id]=='0'
      sql=%Q{select * from clavis.issue where manifestation_id=#{params[:manifestation_id]} and start_number notnull order by issue_id desc limit 1;}
      # logger.warn(sql)
      # @clavis_issue = ClavisIssue.all(:order=>'issue_id desc',:limit=>1,:conditions=>{:manifestation_id=>params[:manifestation_id],:start_number=>params[:start_number]})
      @clavis_issue = ClavisIssue.find_by_sql(sql)
      @clavis_issue = @clavis_issue.first if @clavis_issue!=[]
    else
      @clavis_issue = ClavisIssue.find(params[:id])
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @clavis_issue }
    end
  end

  def check
    cond={}
    [:manifestation_id,:issue_id].each do |t|
      cond[t] = params[t]
    end
    if !ClavisIssue.exists?(cond)
      cond[:issue_volume]='fascicolo autogenerato'
      @clavis_issue=ClavisIssue.create(cond)
    else
      @clavis_issue=ClavisIssue.find(cond[:issue_id])
    end
    headers['Access-Control-Allow-Origin'] = "*"
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @clavis_issue }
    end
  end

end
