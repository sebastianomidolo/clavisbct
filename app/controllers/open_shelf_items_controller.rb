
class OpenShelfItemsController < ApplicationController
  before_filter :set_open_shelf_item, only: [:insert, :delete]
  before_filter :authenticate_user!, only: [:insert, :delete]
  load_and_authorize_resource except: [:show, :insert]

  def index
    @dest_section=params[:dest_section]
    respond_to do |format|
      format.html {
        @records=OpenShelfItem.dewey_list(@dest_section)
      }
    end
  end

  def conteggio
  end

  def estrazione_da_magazzino
    @section=params[:dest_section]
    @escludi_in_prestito=params[:escludi_in_prestito]
    @escludi_ricollocati=params[:escludi_ricollocati]
    if not @section.blank?
      @per_page = params[:per_page].blank? ? 30 : params[:per_page].to_i
      @page = params[:page].blank? ? 1 : params[:page].to_i
      if params[:verb].blank?
        @verb = 'estrai'
      else
        @verb = params[:verb]
      end
      @qs=params[:qs]
      @records=OpenShelfItem.lista_da_magazzino(params[:dest_section],@page,@per_page,@verb,@escludi_in_prestito,@qs,@escludi_ricollocati)
    end
    respond_to do |format|
      format.html
      format.pdf {
        filename="#{@page}_estrazione_da_magazzino.pdf"
        lp=LatexPrint::PDF.new('openshelf_list', @records, false)
        send_data(lp.makepdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
      format.csv {
        page=params[:page].blank? ? '' : "_pagina_#{params[:page]}"
        fname = "barcodes#{page}.csv"
        csv_data=@records.collect {|x| x['barcode'] if x['loan_status']=='A'}
        send_data csv_data.join("\n"), type: Mime::CSV, disposition: "attachment; filename=#{fname}"
      }
    end
  end

  def insert
    @sections=OpenShelfItem.sections.collect {|x| x.last }
    o=OpenShelfItem.find_or_create_by_item_id(@open_shelf_item_id)
    o.created_by=current_user.id
    o.os_section=@dest_section
    o.save
    respond_to do |format|
      format.html {render :text=>"item #{@open_shelf_item_id} aggiunto a scaffale aperto"}
      format.js
    end
  end
  def delete
    @sections=OpenShelfItem.sections.collect {|x| x.last }
    if OpenShelfItem.exists?(@open_shelf_item_id)
      OpenShelfItem.find(@open_shelf_item_id).destroy
    end
    respond_to do |format|
      format.html {render :text=>"item #{@open_shelf_item_id} cancellato da scaffale aperto"}
      format.js
    end
  end

  def show
    headers['Access-Control-Allow-Origin'] = "*"

    render :text=>'not found' if !OpenShelfItem.exists?(params[:id])
    @open_shelf_item=OpenShelfItem.find(params[:id])
    respond_to do |format|
      format.html
      format.json {
        @open_shelf_item[:magazzino]=@open_shelf_item.collocazione_magazzino
        @open_shelf_item[:scaffale_aperto]=@open_shelf_item.collocazione_scaffale_aperto
        render json: @open_shelf_item
      }
    end
  end

  def titles
    @class_id=params[:class_id]
    @close = params[:close].blank? ? false : true
    params[:onshelf]='yes'
    @dest_section=params[:dest_section]
    @clavis_items=ClavisItem.items_ricollocati(params)
    @record={'dewey'=>ClavisAuthority.find(@class_id).full_text,'class_id'=>@class_id,'count'=>@clavis_items.total_entries}
    respond_to do |format|
      format.html
      format.js
    end
  end

  private
  def set_open_shelf_item
    @clavis_item = ClavisItem.find(params[:id])
    @open_shelf_item_id = @clavis_item.id
    @dest_section=params[:dest_section]
  end
  
end
