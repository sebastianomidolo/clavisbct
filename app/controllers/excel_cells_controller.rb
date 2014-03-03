class ExcelCellsController < ApplicationController
  layout 'navbar'

  def show
    @excel_cell=ExcelCell.find(params[:id])
  end
end
