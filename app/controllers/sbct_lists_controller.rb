# coding: utf-8

class SbctListsController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource except: [:new, :create, :destroy, :edit, :update, :man, :delete_future_titles, :remove_all_titles]
  respond_to :html

  def index
    @pagetitle="PAC - Liste d'acquisto"
    @sbct_list = SbctList.new(params[:sbct_list])
    params[:locked]='false' if params[:locked].blank?
    # params[:current_user_id] = current_user.id
    @sbct_lists = SbctList.toc(params)
    if current_user.role?('AcquisitionLibrarian')
      sbct_user = SbctUser.find(current_user.id)
      if sbct_user.sbct_lists.size==0
        sbct_user.create_private_list
      end
    end
    if params[:current_title_id].to_i > 0
      # render text:'cambio lista attiva...' and return
    end
    # user_session[:current_list]=nil
  end

  def show
    render text:'lista privata' and return if @sbct_list.hidden and (@sbct_list.owner_id != current_user.id)
    user_session[:current_list] = @sbct_list.assign_user_session(current_user,user_session[:current_list])
    @pagetitle="PAC - Lista #{@sbct_list.to_label}"
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
    @sbct_list = SbctList.find(params[:id])
    render text:'lista privata' and return if @sbct_list.hidden and (@sbct_list.owner_id != current_user.id)
    
    if can? :new, @sbct_list, current_user
      
    else
      render text:'non autorizzato', layout:true and return
    end

  end

  def update
    @sbct_list = SbctList.find(params[:id])
    if !can? :new, @sbct_list, current_user
      render text:'non autorizzato', layout:true and return      
    end
    respond_to do |format|
      if @sbct_list.update_attributes(params[:sbct_list])
        @sbct_list.updated_by=current_user.id
        @sbct_list.date_updated = Time.now
        @sbct_list.budget_label = params[:budget_label]
        @sbct_list.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_list) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def upload_from_clavis_shelf
    @sbct_list=SbctList.find(params[:id_lista])
    list=SbctList.new(params[:sbct_list])
    #clavis_shelf_id=params[:from_clavis_shelf_id]
    #clavis_shelf_id=params.inspect
    if request.method=="POST"
      # render text:"(da fare) importazione da scaffale #{list.from_clavis_shelf_id}" and return
      @sbct_list.import_titles_from_clavis_shelf(list.from_clavis_shelf_id,current_user)
      redirect_to sbct_list_path(@sbct_list)
    end
  end

  def upload
    @sbct_list=SbctList.find(params[:id_lista])
    @sbct_title = SbctTitle.find(params[:current_title_id].to_i) if !params[:current_title_id].blank?
    if request.method=="POST"
      uploaded_io = params[:filename]
      if uploaded_io.nil?
        render :template=>'d_objects/file_non_specificato'
      else
        fn = uploaded_io.original_filename
        target_filename = File.join('/home/seb/uploaded', fn)
        File.open(target_filename, 'wb') do |file|
          file.write(uploaded_io.read)
        end
        begin
          infotit = params[:current_title_id].to_i == 0 ? '' : "per id_titolo #{params[:current_title_id]}"
          if !infotit.blank?
            # ean=SbctTitle.find(params[:current_title_id].to_i).ean
            ean=@sbct_title.ean
          else
            ean=''
          end
          @sbct_list.load_data_from_excel(target_filename, current_user, ean)
          at_file = "/home/seb/at_load_file_user_#{current_user.email}.txt"
          fd = File.open(at_file,"w")
          # Questa parte in realtà non serve:
          fd.write("# Generato da SbctList#upload - id_lista: #{@sbct_list.id} - filename: #{target_filename} #{infotit} - ean #{ean}\n\n")
          fd.write("LANG='en_US.UTF-8'\n")
          fd.write(%Q{/usr/local/bin/rails runner -e development "u=User.find(#{current_user.id});l=SbctList.find(#{@sbct_list.id});l.load_data_from_excel(%Q{#{target_filename}},u,'#{ean}')"\n});
          fd.close
          #... infatti il cmd non viene invocato...
          # cmd = "at -f #{at_file} now + 1 minute"
          # Kernel.system(cmd)
        rescue
          render text:"<pre>#{$!}</pre>", layout:'sbct' and return
        end
        t_id = params[:current_title_id].to_i
        if t_id==0
          redirect_to sbct_list_path(@sbct_list)
        else
          (
            title=SbctTitle.find(t_id)
            title.updated_by=current_user.id
            # Serve per invocare before and after save di SbctTitle:
            title.current_user=current_user
            title.save
          )
          redirect_to sbct_title_path(t_id)
        end
      end
    else
    end
  end

  def remove_all_titles
    @sbct_list = SbctList.find(params[:id])
    if can? :new, @sbct_list, current_user
    else
      render text:'non autorizzato', layout:true and return
    end
    @sbct_list.remove_all_titles
    redirect_to man_sbct_list_path
  end

  def delete_old_uploads
    sql=%Q{
      DELETE FROM sbct_acquisti.import_copie WHERE id_titolo IN (select id_titolo from sbct_acquisti.import_titoli where id_lista=#{@sbct_list.id});
      DELETE FROM sbct_acquisti.import_titoli WHERE id_lista=#{@sbct_list.id};
    }
    @sbct_list.connection.execute(sql)
    redirect_to sbct_list_path(@sbct_list)
  end

  def delete_future_titles
    @sbct_list = SbctList.find(params[:id])
    if can? :new, @sbct_list, current_user
    else
      render text:'non autorizzato', layout:true and return
    end
    sql=SbctTitle.cancella_titoli_con_data_di_pubblicazione_futura(giorni_nel_futuro=90,id_lista=@sbct_list.id)
    redirect_to man_sbct_list_path(@sbct_list)
    # render text:"<pre>#{sql}</pre>".html_safe
  end

  def create
    @sbct_list = SbctList.new(params[:sbct_list])
    if can? :new, @sbct_list, current_user
      @sbct_list.created_by = current_user.id
      @sbct_list.date_created = Time.now
      # @sbct_list.budget_label = params[:budget_label]
      @sbct_list.save
      respond_with(@sbct_list)
    else
      render text:'non autorizzato', layout:true and return
    end
  end

  def destroy
    user_session[:current_list]=nil
    @sbct_list = SbctList.find(params[:id])
    if can? :new, @sbct_list, current_user
      @sbct_list.destroy
      redirect_to sbct_lists_path
    else
      render text:'non autorizzato', layout:true and return
    end
  end

  def budget_assign
    @sbct_list = SbctList.find(params[:id])
    @sql = @sbct_list.budget_assign
    respond_with(@sbct_list)
  end

  def new
    @sbct_list = SbctList.new
    if !params[:parent_id].blank?
      parent_list = SbctList.find(params[:parent_id].to_i)
      if can? :new, parent_list, current_user
        @sbct_list.parent_id = parent_list.id
        @sbct_list.owner_id = current_user.id
        respond_with(@sbct_list)
      else
        render text:'non autorizzato', layout:true and return
      end
    end
  end
  
  # Manutenzione lista
  def man
    @sbct_list = SbctList.find(params[:id])
    if can? :new, @sbct_list, current_user
    else
      render text:'non autorizzato', layout:true and return
    end
  end

  def assegna_budget_alle_copie_di_questa_lista
  end

  def do_order
    @sbct_title = SbctTitle.new(params[:sbct_title])

    @sbct_list = SbctList.find(params[:id])
    @sbct_budget = @sbct_list.budget(1)
    # render text:@sbct_budget.class and return
    @sbct_supplier = @sbct_budget.sbct_supplier

    @sbct_order = SbctOrder.find_by_sql("SELECT * from sbct_acquisti.orders WHERE inviato=false AND supplier_id=#{@sbct_supplier.id}").first
    if @sbct_order.nil?
      render text:"Non ho trovato nessun ordine aperto, conviene crearne uno nuovo", layout:true and return
    else
      # @sbct_list.ricalcola_prezzi_con_sconto
      # render text:"<pre>#{@sbct_list.sql_for_prepara_ordine(params)}</pre>" and return
      with_sql,@sbct_title,sbct_list,sbct_budgets,sbct_budget=SbctTitle.sql_for_tutti(params,current_user)
      @sql = @sbct_list.sql_for_prepara_ordine(with_sql)
      # render text:"<pre>#{@sql}</pre>" and return
      @sbct_items = SbctItem.paginate_by_sql(@sql, per_page:10000, page:params[:page])
      @prezzo_totale = SbctItem.somma_prezzo(@sbct_items)
    end
  end

end
