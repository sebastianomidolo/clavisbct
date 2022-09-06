# -*- coding: utf-8 -*-

class ExtraCardsController < ApplicationController
  before_filter :set_extra_card, only: [:show, :edit, :update, :destroy, :record_duplicate, :remove_from_container]
  before_filter :authenticate_user!, only: [:show, :edit, :update, :destroy, :record_duplicate, :remove_from_container]
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
    respond_to do |format|
      if @extra_card.update_attributes(params[:extra_card])
        @extra_card.updated_by=current_user
        @extra_card.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@extra_card) }
        format.json { respond_with_bip(@extra_card) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@extra_card) }
      end
    end
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

  def record_duplicate
    @clavis_item_id=@extra_card.clavis_item.item_id
    @extra_card = @extra_card.dup
    @extra_card.login=nil
    @extra_card.created_by=current_user
    @extra_card.save
    @clavis_item=@extra_card.clavis_item
    respond_to do |format|
      format.html { respond_with(@extra_card) }
      format.js
    end
  end

  def remove_from_container
    @container=Container.find(@extra_card.container_id)
    @extra_card.container_id=nil
    @extra_card.save
    respond_to do |format|
      format.html { respond_with(@extra_card) }
      format.js
    end
  end

  def upload_xls
    if request.method=="POST"
      uploaded_io = params[:filename]
      if uploaded_io.nil?
        @message = "File non specificato!"
      else
        fname=File.join(Rails.root.to_s, 'tmp', 'extra_cards_import', uploaded_io.original_filename)
        File.open(fname, 'wb') do |file|
          file.write(uploaded_io.read)
        end
        @basecoll = uploaded_io.original_filename.split('.').first.sub(' ','.')
        @message = "File size #{fname}: #{File.size(fname)} - Original filename: #{uploaded_io.original_filename} - basecoll:#{@basecoll}"
        @data = ExtraCard.load_from_excel(fname,@basecoll,current_user)
      end
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
