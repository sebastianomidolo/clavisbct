class ExcelFilesController < ApplicationController
  layout 'navbar'

  def index
    @excel_files=ExcelFile.summary
  end

  def show
    @excel_file=ExcelFile.find(params[:id])
    @excel_sheets=@excel_file.excel_sheets
    @excel_sheets.each {|es| es.sync}
  end
end
