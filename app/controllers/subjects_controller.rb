class SubjectsController < ApplicationController
  layout 'navbar'

  # GET /subjects
  # GET /subjects.json
  def index
    @pagetitle='Soggettario BCT'
    @subject = Subject.new(params[:subject])

    cond=[]
    if !@subject.heading.blank?
      ts=Subject.connection.quote_string(@subject.heading.split.join(' & '))
      cond << "to_tsvector('simple', heading) @@ to_tsquery('simple', '#{ts}') and not heading ~ '^[aiv]'"
      # cond << "to_tsvector('simple', heading) @@ to_tsquery('simple', '#{ts}')"
    end
    if !@subject.clavis_subject_class.blank?
      cond << "clavis_subject_class = #{Subject.connection.quote(@subject.clavis_subject_class)}"
    end
    if @subject.inbct==true
      cond << "inbct is true"
    end
    cond = cond==[] ? 'false' : cond.join(" AND ")

    @subjects = Subject.paginate(:conditions=>cond,:per_page=>300,:page=>params[:page], :order=>'heading')
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @subjects }
    end
  end

  # GET /subjects/1
  # GET /subjects/1.json
  def show
    if params[:clavis_authority_id].blank?
      @subject = Subject.find(params[:id])
    else
      @subject = Subject.find_by_clavis_authority_id(params[:clavis_authority_id])
      if @subject.nil?
        @subject = Subject.find_by_sql("SELECT s.* FROM clavis.authority ca JOIN subjects s ON(s.heading=ca.full_text) WHERE ca.authority_id=#{params[:clavis_authority_id]} AND s.inbct").first
      end
      if @subject.nil? or @subject.inbct == false
        @bncf_term=ClavisAuthority.find(params[:clavis_authority_id]).bncf_terms.first
        if !@bncf_term.nil?
          render :template=>'bncf_terms/show' and return 
        else
          render :text=>"Niente di pertinente alla voce di authority #{params[:clavis_authority_id]}" and return if @subject.nil? or @subject.inbct == false
        end
      end
    end
    @pagetitle="Soggettario BCT: #{@subject.heading} "
    @embedded = params[:embedded].blank? ? nil : true
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @subject }
    end
  end

  def duplicate_terms
    @subjects=Subject.duplicate_terms
  end
end
