# -*- coding: utf-8 -*-

class ExtraCardsController < ApplicationController
  before_filter :set_extra_card, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource except: [:show, :index]


  respond_to :html

  def index
    @extra_card = ExtraCard.new(params[:extra_card])
    @attrib=@extra_card.attributes.collect {|a| a if not a.last.blank?}.compact
    toskip=["id_titolo", "id_copia"]
    @attrib.delete_if do |r|
      toskip.include?(r.first)
    end

    cond=[]
    @extra_cards = ExtraCard.paginate_by_sql("SELECT * FROM topografico_non_in_clavis WHERE false", :page=>1);
    @attrib.each do |a|
      name,value=a
      case name
      when 'titolo'
        ts=ExtraCard.connection.quote_string(value.split.join(' & '))
        cond << "to_tsvector('simple', titolo) @@ to_tsquery('simple', '#{ts}')"
      when 'mancante'
        x = value=='1' ? 'true' : 'false'
        cond << "#{name} is #{x}"
      when 'inventory_number'
        cond << "#{name}=#{value}"
      else
        ts=ExtraCard.connection.quote_string(value)
        cond << "#{name} ~* '#{ts}'"
      end
    end
    cond = cond.join(" AND ")
    @sql_conditions=cond
    order_by = cond.blank? ? nil : 'espandi_collocazione(collocazione)'
    per_page = params[:per_page].blank? ? 200 : params[:per_page]
    @extra_cards = ExtraCard.paginate(:conditions=>cond,:page=>params[:page], per_page:per_page, :order=>order_by)
    respond_with(@extra_cards)
  end

  def show
    respond_with(@extra_card)
  end

  def new
    olid=params[:home_library_id].blank? ? 2 : params[:home_library_id]
    @extra_card = ExtraCard.new(home_library_id: olid, collocazione:params[:collocazione])
    respond_with(@extra_card)
  end

  def edit
  end

  def create
    @extra_card = ExtraCard.new(params[:extra_card])
    @extra_card.created_by=current_user
    @extra_card.save
    respond_with(@extra_card)
  end

  def update
    @extra_card.update_attributes(params[:extra_card])
    @extra_card.updated_by=current_user
    @extra_card.save
    flash[:notice] = "Modifiche salvate"
    respond_with(@extra_card)
  end

  def destroy
    if @extra_card.deleted?
      @extra_card.deleted=false
      flash[:notice] = "Richiamata in vita"
    else
      @clavis_item_id=@extra_card.clavis_item.item_id
      @extra_card.deleted=true
      flash[:notice] = "Scheda contrassegnata come cancellata"
    end
    @extra_card.save
    respond_to do |format|
      format.html { respond_with(@extra_card) }
      format.js
    end
  end

  private
    def set_extra_card
      if !params[:colloc].blank?
        @extra_cards = ExtraCard.where(:collocazione=>params[:colloc])
        if @extra_cards.size==1
          @extra_card = @extra_cards[0]
        else
          redirect_to :action=>:index,:collocazione=>params[:colloc]
        end
      else
        @extra_card = ExtraCard.find(params[:id])
      end
    end
end
