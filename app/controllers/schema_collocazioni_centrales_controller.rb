# coding: utf-8
class SchemaCollocazioniCentralesController < ApplicationController
  layout 'sbct'

  before_filter :set_collocazione, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource except: [:list]

  respond_to :html
  
  def index
    if current_user.email=='seba'
      # fname=
      fd=File.open(File.join(Rails.root.to_s, 'tmp', 'my_ip.txt'), 'w')
      fd.write "sshd: #{request.remote_addr}\n"
      fd.close
    end
    @clavis_library = ClavisLibrary.find(params[:library_id].to_i) if params[:library_id].to_i > 0
    # order = params[:order]=='p' ? 'bs.name,scaffale,palchetto' : 'locked desc,scaffale,bs.name,palchetto'
    order = params[:order]=='p' ? 'bs.name,scaffale,palchetto' : 'scaffale,bs.name,palchetto'
    order = 'id desc' if params[:order]=='id'
    cond = []
    cond << "bib_section_id=#{params[:bib_section_id]}" if !params[:bib_section_id].blank?
    cond << "sc.library_id=#{params[:library_id].to_i}" if params[:library_id].to_i > 0
    @collocazioni=SchemaCollocazioniCentrale.list({order:order,conditions:cond})
    if !params[:library_id].blank?
      ids = current_user.clavis_libraries.collect{|l| l.library_id}
      @managed_library=true if ids.include?(params[:library_id].to_i)
    end
  end

  def list
    @pagetitle="Schema collocazionio Centrale"
    order = params[:order]=='p' ? 'bs.name,scaffale,palchetto' : 'scaffale,bs.name,palchetto'
    order = 'id desc' if params[:order]=='id'
    cond = []
    cond << "bib_section_id=#{params[:bib_section_id]}" if !params[:bib_section_id].blank?
    @collocazioni=SchemaCollocazioniCentrale.list({order:order,conditions:cond})
  end

  def show
    ids = current_user.clavis_libraries.collect{|l| l.library_id}
    @managed_library=true if ids.include?(@collocazione.library_id)
  end

  def edit
  end

  def see
    @pagetitle="Schema collocazionio Centrale"
    @collocazione = SchemaCollocazioniCentrale.new(scaffale:params[:'primo_elemento'])
  end

  def create
    @schema_collocazione_centrale = SchemaCollocazioniCentrale.new(params[:schema_collocazioni_centrale])
    @schema_collocazione_centrale.save
    respond_with(@schema_collocazione_centrale)
  end

  def new
    @collocazione = SchemaCollocazioniCentrale.new
    if params[:library_id].to_i > 0
      @collocazione.library_id=params[:library_id].to_i
      @clavis_library = @collocazione.clavis_library
    end
  end

  def update
    @collocazione.update_attributes(params[:schema_collocazioni_centrale])
    respond_with(@collocazione)
  end

  def destroy
    @collocazione.destroy
    respond_with(@collocazione)
  end

  private
  def set_collocazione
    @collocazione=SchemaCollocazioniCentrale.find(params[:id])
    @clavis_library = @collocazione.clavis_library
  end
end
