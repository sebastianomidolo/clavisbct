# coding: utf-8

class SbctListsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource
  respond_to :html

  def index
    @pagetitle="CR - Liste d'acquisto"
    @sbct_list = SbctList.new(params[:sbct_list])
    @sbct_lists = SbctList.toc(params)
  end

  def show
    @pagetitle="CR - Lista #{@sbct_list.to_label}"
    sql=%Q{select original_filename,date_created,count(*) from sbct_acquisti.import_titoli
             where id_lista=#{@sbct_list.id}
                group by original_filename,date_created order by original_filename,date_created}
    @imported_titles_index=SbctList.find_by_sql(sql)
    sql=%Q{select id_lista,reparto,sottoreparto,count(*) from sbct_acquisti.import_titoli
        where reparto is not null and id_lista=#{@sbct_list.id} group by id_lista,reparto,sottoreparto order by reparto,sottoreparto}
    sql=%Q{select reparto,sottoreparto,count(*) from sbct_acquisti.import_titoli
        where id_lista=#{@sbct_list.id} and reparto is not null group by reparto,sottoreparto order by reparto,sottoreparto;}
    @imported_titles_toc=SbctList.find_by_sql(sql)
  end

  def edit
  end

  def update
    @sbct_list = SbctList.find(params[:id])
    respond_to do |format|
      if @sbct_list.update_attributes(params[:sbct_list])
        @sbct_list.updated_by=current_user.id
        @sbct_list.budget_label = params[:budget_label]
        @sbct_list.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_list) }
      else
        format.html { render :action => "edit" }
      end
    end
  end


  def upload
    @sbct_list=SbctList.find(params[:id_lista])
    if request.method=="POST"
      uploaded_io = params[:filename]
      if uploaded_io.nil?
        render :template=>'d_objects/file_non_specificato'
      else
        target_filename = File.join('/home/seb/uploaded', uploaded_io.original_filename)
        File.open(target_filename, 'wb') do |file|
          file.write(uploaded_io.read)
        end
        begin
          @sbct_list.load_data_from_excel(target_filename, current_user)
        rescue
          render text:"<pre>#{$!}</pre>", layout:'sbct' and return
        end
        redirect_to sbct_list_path(@sbct_list)
      end
    else
    end
  end

  def create
    @sbct_list = SbctList.new(params[:sbct_list])
    @sbct_list.created_by = current_user.id
    @sbct_list.budget_label = params[:budget_label]
    @sbct_list.save
    respond_with(@sbct_list)
  end

  def associa_a_budget
    @sbct_list = SbctList.find(params[:id])
    @sbct_budget = SbctBudget.find(params[:budget_id]) if !params[:budget_id].nil?
    @msg = @sbct_budget.associa_a_lista(@sbct_list)
    respond_to do |format|
      format.html
      format.js {
      }
    end
  end

  def new
    @sbct_list = SbctList.new
    respond_with(@sbct_list)
  end

  
  # Test: https://clavisbct.comperio.it/sbct_lists/3508/report
  # NON USATA
  def report
    @sbct_list = SbctList.find(params[:id])
  end

  def do_order
    @sbct_list = SbctList.find(params[:id])
    # @sbct_list.budgets_assign
    begin
      # @sbct_list.assegna_fornitore
    rescue
    end
    # @sbct_list.ricalcola_prezzi_con_sconto
    @sbct_items = SbctItem.paginate_by_sql(@sbct_list.sql_for_prepara_ordine, per_page:10000, page:params[:page])
  end

end
