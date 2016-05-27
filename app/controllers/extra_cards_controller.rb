# -*- coding: utf-8 -*-

class ExtraCardsController < ApplicationController
  before_filter :set_extra_card, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:show, :edit, :update, :destroy]
  load_and_authorize_resource except: [:show, :index]


  respond_to :html

  def index
    cond={}
    cond[:collocazione]=params[:collocazione] if !params[:collocazione].blank?
    @extra_cards = ExtraCard.paginate(:conditions=>cond,:per_page=>300,:page=>params[:page])
    respond_with(@extra_cards)
  end

  def show
    respond_with(@extra_card)
  end

  def new
    olid=params[:owner_library_id].blank? ? 2 : params[:owner_library_id]
    @extra_card = ExtraCard.new(owner_library_id: olid)
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
