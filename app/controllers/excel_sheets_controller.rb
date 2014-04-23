class ExcelSheetsController < ApplicationController
  layout 'navbar'

  def show
    @excel_sheet=ExcelSheet.find(params[:id])
    @view_number=params[:view_number].blank? ? nil : params[:view_number].to_i
    if params[:group].blank?
      @records=@excel_sheet.sql_paginate(params, :page=>params[:page])
    else
      @column_number=params[:group].to_i
      @records=@excel_sheet.sql_paginate_group_by(params,:page=>params[:page])
      render template: '/excel_sheets/group'
    end
  end

end
