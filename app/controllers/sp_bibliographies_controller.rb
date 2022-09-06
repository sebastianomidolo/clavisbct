# coding: utf-8
class SpBibliographiesController < ApplicationController
  layout 'sp_bibliographies'

  before_filter :authenticate_user!, only: [:create,:update,:destroy,:edit]
  before_filter :set_sp_bibliography_id, only: [:show,:edit,:update,:destroy,:clavisbct_include]
  load_and_authorize_resource only: [:new,:create,:update,:destroy,:edit,:admin,:users]
  respond_to :html

  def index
    @h1_title='Proposte bibliografiche'
    @h2_title='Elenco cronologico'
    @css_id='bibliografie'

    @sp_bibliography = SpBibliography.new(params[:sp_bibliography])
    
    qs=params[:qs]
    cond=[]
    if !qs.blank?
      ts=SpBibliography.connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('simple', description) @@ to_tsquery('simple', '#{ts}')"
    end
    # cond << "library_id=#{params[:library_id]}" if !params[:library_id].blank?

    #--------------
    @attrib=@sp_bibliography.attributes.collect {|a| a if not a.last.blank?}.compact
    toskip=["comment"]
    @attrib.delete_if do |r|
      toskip.include?(r.first)
    end
    @sp_bibliographies=[]
    @attrib.each do |a|
      name,value=a
      case name
      when 'title'
        ts=SpBibliography.connection.quote_string(textsearch_sanitize(value))
        cond << "to_tsvector('simple', title) @@ to_tsquery('simple', '#{ts}')"
      when 'library_id'
        cond << "library_id=#{value}"
      end
    end
    
    @not_admin_user=false
    if user_signed_in?
      cond = cond.join(" AND ")
      if can? :manage, SpBibliography
        # @sp_bibliographies = SpBibliography.paginate(:page=>params[:page], per_page:500, :order=>'title')
        @sp_bibliographies = SpBibliography.paginate(:conditions=>cond, :page=>params[:page], :per_page=>500, :order=>'sp_bibliographies.id desc')
      else
        @sp_bibliographies = current_user.sp_bibliographies.paginate(:page=>params[:page], per_page:50)
        @not_admin_user=true
      end
    else
      cond << "sp_bibliographies.status IN('A','C')"
      cond = cond.join(" AND ")
      @sp_bibliographies = SpBibliography.paginate(:conditions=>cond, :page=>params[:page], :per_page=>500, :order=>'title')
    end

    respond_to do |format|
      format.html {
        render :layout=>params[:layout] if !params[:layout].blank?
      }
    end
  end

  def show
    # render text:'Risorsa non pubblicata' and return if current_user.nil? and !@sp_bibliography.published
    if current_user.nil?
      render text:"Risorsa non disponibile", layout:'sp_bibliographies' and return if !@sp_bibliography.published?
    else
    end
    @h1_title='Proposte bibliografiche'
    @h1_link="/sp_bibliographies"
    @h2_title=@sp_bibliography.title[0..80]
    @css_id='bibliografie'
    @pagetitle=@sp_bibliography.title
    
    respond_to do |format|
      format.html {
        render :layout=>params[:layout] if !params[:layout].blank?
      }
      format.pdf {
        filename="#{@sp_bibliography.title}.pdf"
        lp=LatexPrint::PDF.new('sp_bibliography', [@sp_bibliography])
        send_data(lp.makepdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
    end
  end

  def new
    @sp_bibliography = SpBibliography.new
    respond_with(@sp_bibliography)
  end

  def create
    @sp_bibliography=SpBibliography.new(params[:sp_bibliography])
    # render text:current_user.email and return
    @sp_bibliography.created_by=current_user.id
    @sp_bibliography.save
    @sp_bibliography.users << current_user
    @sp_user = SpUser.find(@sp_bibliography.id,current_user.id)
    @sp_user.auth='SpBibliography,SpSection,SpItem';
    @sp_user.save
    respond_with(@sp_bibliography)
  end

  def edit
  end

  def update
    params[:sp_bibliography][:updated_by] = current_user.id
    @sp_bibliography.update_attributes(params[:sp_bibliography])
    respond_with(@sp_bibliography)
  end

  def cover_image
    b=SpBibliography.find(params[:id])
    send_file(b.cover_image, :type=>'image/jpeg; charset=binary', :disposition => 'inline')
  end

  def check_items
    @sp_bibliography=SpBibliography.find(params[:id])
  end

  def admin
  end

  def add_user
    if !params[:user_id].blank?
      sql="insert into roles_users(user_id,role_id) values(#{params[:user_id]}, 43)"
      User.connection.execute(sql)
      redirect_to users_sp_bibliographies_path
    end
  end

  def users
    if !params[:user_id].nil?
      @user = User.find(params[:user_id])
      if !params[:managed_bib].blank?
        bib=SpBibliography.find(params[:managed_bib])
        if @user.sp_bibliographies.include?(bib)
          @user.sp_bibliographies.delete(bib)
        else
          SpUser.create(bibliography_id:bib.id,user_id:@user.id, auth:'SpBibliography,SpSection,SpItem')
        end
      end
      render 'sp_user_edit'
    end
  end

  def destroy
    cnt = @sp_bibliography.sp_items.count
    render text:"Non si può cancellare la bibliografia #{@sp_bibliography.title}: contiene #{cnt} schede", layout:true and return if cnt>0
    @sp_bibliography.destroy
    redirect_to sp_bibliographies_path
  end

  def clavisbct_include
  end

  private
  def set_sp_bibliography_id
    if SpBibliography.column_names.include?('orig_id')
      id = params[:id].to_i > 0 ? params[:id] : SpBibliography.find_by_orig_id(params[:id]).id
    else
      id = params[:id]
    end
    @sp_bibliography=SpBibliography.find(id)
  end
end
