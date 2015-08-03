class BncfTermsController < ApplicationController

  def index
  end
  def show
    @bncf_term = BncfTerm.find(params[:id])
  end
  def obsolete_terms
  end
  def missing_terms
    @starts_with=params[:starts_with]
  end
end
