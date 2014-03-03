class ExcelFilesController < ApplicationController
  layout 'navbar'

  def index
    @excel_files=ExcelFile.all
  end

  def show
    @excel_file=ExcelFile.find(params[:id])
    if params[:qs].blank?
      @excel_cells=[]
    else
      @excel_sheets=@excel_file.excel_sheets
      @excel_cells=ExcelCell.where(:excel_sheet_id=>@excel_sheets).where("cell_content ~* '#{params[:qs]}'")
    end
  end
end
