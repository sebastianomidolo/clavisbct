class ExcelSheetsController < ApplicationController
  layout 'navbar'

  def show
    if params[:id].to_i==0
      @excel_sheet=ExcelSheet.find_by_tablename(params[:id])
      render text: 'errore, tabella non trovata' and return if @excel_sheet.nil?
    else
      @excel_sheet=ExcelSheet.find(params[:id])
    end
    @view_number=params[:view_number].blank? ? nil : params[:view_number].to_i
    render template: '/excel_sheets/row' and return if !params[:row].blank?
    if params[:group].blank?
      @records=@excel_sheet.sql_paginate(params, :page=>params[:page], :per_page=>100)
    else
      @column_number=params[:group].to_i
      @records=@excel_sheet.sql_paginate_group_by(params,:page=>params[:page], :per_page=>1000)
      render template: '/excel_sheets/group'
    end
  end

end
