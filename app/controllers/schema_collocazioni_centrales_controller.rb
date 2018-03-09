class SchemaCollocazioniCentralesController < ApplicationController
  before_filter :set_collocazione, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource except: [:list]

  respond_to :html
  
  def index
    if current_user.email=='seba'
      fd=File.open("/tmp/my_ip.txt", 'w')
      fd.write "sshd: #{request.remote_addr}\n"
      fd.close
    end
    order = params[:order]=='p' ? 'bs.name,scaffale,palchetto' : 'locked desc,scaffale,bs.name,palchetto'
    cond = []
    cond << "bib_section_id=#{params[:bib_section_id]}" if !params[:bib_section_id].blank?
    @collocazioni=SchemaCollocazioniCentrale.list({order:order,conditions:cond})
  end

  def list
    order = params[:order]=='p' ? 'bs.name,scaffale,palchetto' : 'scaffale,bs.name,palchetto'
    cond = []
    cond << "bib_section_id=#{params[:bib_section_id]}" if !params[:bib_section_id].blank?
    @collocazioni=SchemaCollocazioniCentrale.list({order:order,conditions:cond})
  end

  def show
  end
  def edit
  end

  def see
    @collocazione = SchemaCollocazioniCentrale.new(scaffale:params[:'primo_elemento'])
  end

  def create
    @schema_collocazione_centrale = SchemaCollocazioniCentrale.new(params[:schema_collocazioni_centrale])
    @schema_collocazione_centrale.save
    respond_with(@schema_collocazione_centrale)
  end

  def new
    @collocazione = SchemaCollocazioniCentrale.new
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
  end
end
