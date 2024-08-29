class DiscardRulesController < ApplicationController
  layout 'clinic'
  load_and_authorize_resource
  before_filter :authenticate_user!
  respond_to :html

  def index
    @pagetitle='Inserimento/modifica regole SMUSI per lo scarto'

    cond = params[:pubblico].blank? ? '' : "where pubblico=#{DiscardRule.connection.quote(params[:pubblico])}"
    sql = %Q{select * from #{DiscardRule.table_name}
      #{cond} order by classe_from nulls last,descrizione
    }
    @discard_rules = DiscardRule.find_by_sql(sql)
  end

  def new
  end

  def create
    @discard_rule = DiscardRule.new(params[:discard_rule])
    @discard_rule.save
    # respond_with(@discard_rule)
    redirect_to discard_rules_path
  end

  def edit
  end

  def show
  end

  def update
    @discard_rule.update_attributes(params[:discard_rule])
    # respond_with(@discard_rule)
    redirect_to discard_rules_path
  end

  
end
