class ExcelSheetsController < ApplicationController
  layout 'navbar'

  def show
    @excel_sheet=ExcelSheet.find(params[:id])
    @cell_column=params[:cell_column]
    if params[:qs].blank?
      if @cell_column.blank?
        @excel_cells=ExcelCell.where(:excel_sheet_id=>@excel_sheet.id).limit(2)
      else
        @excel_cells=ExcelCell.where(:excel_sheet_id=>@excel_sheet.id,cell_column: @cell_column).order(:cell_content)
        # @excel_cells=ExcelCell.select("cell_content,excel_sheet_id,count(*)").where(:excel_sheet_id=>@excel_sheet.id,cell_column: @cell_column).order(:cell_content).group(:cell_content,:excel_sheet_id)
      end
    else
      @excel_cells=ExcelCell.where(:excel_sheet_id=>@excel_sheet.id).where("cell_content ~* '#{params[:qs]}'")
    end
  end
end
