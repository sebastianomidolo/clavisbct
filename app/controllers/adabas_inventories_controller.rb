class AdabasInventoriesController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  respond_to :html

  def index
    cond=[]
    @tipo_ricerca=""
    qs = params[:qs]
    if !qs.blank?
      serie,inv=qs.split('-')
      if inv.to_i > 0
        cond << "serie=#{ActiveRecord::Base::connection.quote(serie.upcase)}"
        cond << "inv=#{inv}"
        @tipo_ricerca="serie e inventario"
      else
        if serie.size==10
          cond << "bid=#{ActiveRecord::Base::connection.quote(serie.upcase)}"
          @tipo_ricerca="BID"
        else
          if serie.to_i>0
            cond << "inv=#{serie.to_i}" 
            @tipo_ricerca="numero di inventario"
          end
        end
      end
    end
    if cond==[] and !qs.blank?
      ts=ActiveRecord::Base::connection.quote_string(qs.split.join(' & '))
      cond << "to_tsvector('english', isbd) @@ to_tsquery('english', '#{ts}')"
      @tipo_ricerca="parole nel titolo"
    end
    cond = cond==[] ? 'false' : cond.join(' AND ')
    @sql_conditions=cond
    @adabas_inventories = AdabasInventory.paginate(:conditions=>cond,:page=>params[:page], order:'serie,inv')
  end

  def show
    @adabas_inventory=AdabasInventory.find(params[:id])
    respond_to do |format|
      format.html { respond_with(@adabas_inventory) }
      format.js
    end
  end
end
