# coding: utf-8
class SpSectionsController < ApplicationController
  layout 'sp_bibliographies'
  before_filter :authenticate_user!, only: [:new,:create,:update,:destroy,:edit]
  before_filter :set_sp_section_id, only: [:new,:show,:edit,:update,:destroy]
  load_and_authorize_resource only: [:new,:create,:update,:destroy,:edit]
  respond_to :html

  def index
    @sp_bibliography=SpBibliography.find(params[:bibliography_id])
    @sp_sections=@sp_bibliography.sp_sections
  end

  def show
    if current_user.nil?
      render text:"Risorsa #{@sp_section.id} non disponibile",layout:'sp_bibliographies' and return if @sp_section.published? == false
    end

    @h1_title='Proposte bibliografiche'
    @h1_link="/sp_bibliographies"
    @h2_title=@sp_section.sp_bibliography.title
    @css_id='bibliografie'
    # render text:0 and return
    @pagetitle=@sp_section.title
    respond_to do |format|
      format.html {
        render :layout=>params[:layout] if !params[:layout].blank?
      }
      format.pdf {
        # https://clavisbct.comperio.it/sp_sections/243,13.pdf?formato=copertine
        filename="#{@sp_bibliography.title}.pdf"
        if params[:formato]=='copertine'
          # Di fatto non viene usato - 12 marzo 2024
          (
            prms = Hash.new
            prms[:metadata] = Hash.new
            prms[:nologo]=true
            prms[:with_watermark]=true
            prms[:force]=true
            objs=[]
            cnt = 0
            @sp_section.sp_items.each do |i|
              next if i.manifestation_id.nil?
              cnt += 1
              obj = ClavisManifestation.find(i.manifestation_id).clavis_cover_cached
              # obj = DObject.find(441)
              objs << obj
              prms[:metadata][obj.id] = [i.manifestation_id,i.bibdescr,i.collciv]
              break if cnt > 5
            end
            # raise "metadata: #{prms[:metadata]}"
            f=DObject.to_pdf(objs,filename,prms);nil
            send_file(f, :filename=>filename, :type=>'application/pdf', :disposition => 'inline')
          )
        else
          lp=LatexPrint::PDF.new('sp_bibliography', [@sp_bibliography,@sp_section])
          send_data(lp.makepdf,
                    :filename=>filename,:disposition=>'inline',
                    :type=>'application/pdf')
        end
      }
    end
  end

  def edit
  end

  def new
    @sp_section = SpSection.new
    @sp_bibliography=SpBibliography.find(params[:bibliography_id])
    @sp_section.sp_bibliography = @sp_bibliography
    @sp_section.parent = params[:parent]
    respond_with(@sp_section)
  end

  def create
    sp_section=SpSection.new(params[:sp_section])
    sp_bibliography=SpBibliography.find(sp_section.bibliography_id)
    sp_section.number = sp_bibliography.next_section_number
    sp_section.parent = 0 if sp_section.parent.blank?
    sp_section.created_by=current_user.id
    sp_section.save
    redirect_to sp_section_path(sp_section, :number=>sp_section.number)
  end

  def update
    upd = params[:sp_section]
    upd['parent'] = 0 if upd['parent'].blank?
    upd['parent'] = @sp_section.parent if upd['parent'] == upd['number']
    upd['updated_by'] = current_user.id
    @sp_section.update_attributes(upd)
    respond_with(@sp_section)
  end

  def destroy
    @sp_section.destroy
    redirect_to sp_bibliography_path(@sp_bibliography)
  end

  private
  def set_sp_section_id
    if params[:id].blank?
      @sp_section=SpSection.new
      @sp_bibliography=SpBibliography.find(params[:bibliography_id])
      @sp_section.sp_bibliography=@sp_bibliography
    else
      @sp_section=SpSection.find(params[:id])
      @sp_bibliography=@sp_section.sp_bibliography
    end
  end
end
