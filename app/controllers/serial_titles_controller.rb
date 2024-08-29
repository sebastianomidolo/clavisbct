# coding: utf-8

class SerialTitlesController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_title, only: [:index, :show, :edit, :update, :destroy, :print, :subscr]
  before_filter :check_list_owner, only: [:new, :create]
  load_and_authorize_resource except: [:index]
  respond_to :html

  # Nota: impostare da qualche parte set lc_monetary to "it_IT.utf8";
  
  def index
    invoice_filter_enabled=params[:invoice_id].blank? ? false : true
    @serial_titles=SerialTitle.trova(params,invoice_filter_enabled)
    @pagetitle=SerialList.find(params[:serial_list_id].to_i).title
    if current_user.nil?
      render template:'serial_titles/index_public'
    else
      user_session[:current_library] = params[:library_id]
    end
  end

  def new
    @serial_title = SerialTitle.new
    @serial_title.serial_list_id=@serial_list.id
    @pagetitle="#{SerialList.find(params[:serial_list_id]).title} - inserimento titolo"
    respond_with(@serial_title)
  end

  def edit
    @pagetitle="modifica #{@serial_title.title}"
  end

  def create
    @serial_title=SerialTitle.new(params[:serial_title])
    @serial_title.serial_list_id=params[:serial_list_id]
    @serial_list = @serial_title.serial_list
    @serial_title.updated_by=current_user.id
    @serial_title.save
    respond_with(@serial_title)
  end

  def update
    params[:serial_title][:updated_by]=current_user.id
    @serial_title.update_attributes(params[:serial_title])
    @serial_list = @serial_title.serial_list
    respond_with(@serial_title, :location=>serial_title_path(params.slice(:serial_list_id,:library_id,:estero,:tipo_fornitura,:sospeso)))
  end

  def destroy
    serial_list_id=@serial_title.serial_list_id
    @serial_title.destroy
    redirect_to serial_titles_path(serial_list_id:serial_list_id)
  end

  def subscr
    @pagetitle="#{@serial_title.title}"
  end

  def show
    respond_to do |format|
      format.html {
        @pagetitle="#{@serial_title.title}"
      }
      format.js {
        @library_id=params[:library_id].to_i
        if !params[:tipo_fornitura].blank?
          @tf = @serial_title.connection.quote(params[:tipo_fornitura])
          sql = %Q{INSERT INTO #{SerialSubscription.table_name} (serial_title_id, library_id, tipo_fornitura, updated_by)
                        values (#{@serial_title.id},#{@library_id},#{@tf},#{current_user.id})
                    ON CONFLICT (serial_title_id, library_id) DO UPDATE set tipo_fornitura = #{@tf}, updated_by=#{current_user.id}}
          @message = "ok"
          @serial_title.connection.execute(sql)
          SerialSubscription.find(@serial_title.id,@library_id).save
        else
          sql = %Q{DELETE FROM #{SerialSubscription.table_name} WHERE serial_title_id=#{@serial_title.id} AND library_id=#{@library_id}}
          @message = "cancellato"
          @serial_title.connection.execute(sql)
        end
      }
    end
  end

  def check_list_owner
    @serial_list = SerialList.find(params[:serial_list_id])
    if current_user.nil?
    else
      if !can? :manage, SerialList
        render text:'operazione non autorizzata',layout:true if !@serial_list.owned_by?(current_user)
      end
    end
  end
  
  def print
    @serial_titles=SerialTitle.trova(params)
    respond_to do |format|
      format.html
      format.pdf {
        parametri = params
        @serial_titles.define_singleton_method(:params) do
          parametri
        end
        lp=LatexPrint::PDF.new('serial_titles', @serial_titles)
        send_data(lp.makepdf,
                  :filename=>'elenco.pdf',:disposition=>'inline',
                  :type=>'application/pdf')
      }
      format.csv {
        require 'csv'
        titolo_lista = SerialList.find(params[:serial_list_id]).formula_titolo(params,' - ').squeeze(' ')
        csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
          if !params[:includi_note_fornitore].blank?
            csv << [titolo_lista,'Note per il fornitore']
          else
            csv << [titolo_lista]
          end
          @serial_titles.each do |r|
            # csv << [r.title.gsub("'","’")]
            if !params[:includi_note_fornitore].blank?
              csv << [r.title,r.note_fornitore]
            else
              csv << [r.title]
            end
          end
        end

        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=#{titolo_lista}.csv"
      }
    end
  end

  private
  def set_serial_title
    if params[:id].blank?
      @serial_title = SerialTitle.new(params[:serial_title])
    else
      @serial_title = SerialTitle.find(params[:id])
      if params[:serial_list_id].blank?
        params[:serial_list_id]=@serial_title.serial_list_id
      end
    end
    if @serial_title.id.nil?
      @serial_list = SerialList.find(params[:serial_list_id])
    else
      @serial_list = SerialList.find(@serial_title.serial_list_id)
    end
    self.check_list_owner
  end

end

