# coding: utf-8
class SerialTitlesController < ApplicationController
  layout 'periodici'
  before_filter :set_serial_title, only: [:index, :show, :edit, :update, :destroy, :print]
  before_filter :check_list_owner, only: [:new, :create]
  load_and_authorize_resource
  respond_to :html

  # Nota: impostare da qualche parte set lc_monetary to "it_IT.utf8";
  
  def index
    @serial_titles=SerialTitle.trova(params)
  end

  def new
    @serial_title = SerialTitle.new
    @serial_title.serial_list_id=@serial_list.id
    respond_with(@serial_title)
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
  
  def show
    respond_to do |format|
      format.html
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
    if !can? :manage, SerialList
      render text:'operazione non autorizzata',layout:true if !@serial_list.owned_by?(current_user)
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

