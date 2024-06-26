# coding: utf-8

class SbctTitlesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource

  respond_to :html

  def homepage
    user_session[:tinybox] = [] if user_session[:tinybox].nil?
    @pagetitle="PAC - HomePage"
    @sbct_title = SbctTitle.new(params[:sbct_title])
    if SbctTitle.user_roles(current_user).include?('AcquisitionLibrarian')
      # user_session[:current_library] = current_user.clavis_libraries.first.id
      if current_user.clavis_default_library.nil? or current_user.clavis_default_library.siglabct.blank?
        user_session[:current_library] = nil
      else
        user_session[:current_library] = current_user.clavis_librarian.default_library_id
      end
    end
    if (current_user.role?(['AcquisitionManager','AcquisitionStaffMember'])) and !params[:fmt].blank?
      hfmt = [
        'analisi_biblioteche',
        'analisi_liste',
        'analisi_reparti',
        'autoseleziona_copie',
        'mass_edit',
        'budget_assign',
        'manutenzione_lista',
      ]
      if hfmt.include?(params[:fmt])
        render "fmt_#{params[:fmt]}" and return
        # render text:"<pre>\nfmt_#{params[:fmt]} con sql uguale a #{user_session[:current_sql]}\n</pre>" and return
      end
    end
    user_session[:sbct_titles_ids]=nil
    user_session[:delivery_notes_mode]=nil

    #mylist = current_user.sbct_lists.first
    #user_session[:current_list] = mylist.nil? ? nil : mylist.id
    # render template:'sbct_titles/aggiornamento_in_corso' if current_user.email!='seba'
  end

  def clavis_sql_items_insert
    render text:"<pre>#{@sbct_title.clavis_sql_items_insert}</pre>"
  end

  def move_items_to_other_title
    user_session[:sbct_titles_ids]=nil
    # Titolo da eliminare:
    @sbct_title.elimina_duplicato(SbctTitle.find(params[:target_title]), current_user.id)
    respond_with(@sbct_title)
  end

  def stampa_assegnazioni_copie
    if params[:id_copia].blank?
      if params[:order_id].blank? and !params[:data_arrivo].blank?
        @sbct_order = SbctOrder.new
        filename="arrivati_#{params[:data_arrivo]}.pdf"
      else
        if params[:dnoteid].blank?
          @sbct_order = SbctOrder.find(params[:order_id])
          filename="#{@sbct_order.to_label}.pdf"
        else
          @sbct_order = SbctOrder.new
        end
      end
    else
      @sbct_order = SbctOrder.new
      filename="bigliettini.pdf"
    end

    items = SbctItem.order_items(@sbct_order,params)
    items = SbctItem.rearrange_items(items)

    pdf=SbctTitle.pdf_per_assegnazione_copie(items)

    respond_to do |format|
      format.html {
        render text:"filename: #{filename} - pdf: #{pdf}"
      }
      format.pdf  {
        # filename="#{@sbct_order.to_label}.pdf"
        # pdf=SbctTitle.pdf_per_assegnazione_copie(@sbct_items)
        send_data(pdf, :filename=>filename,:disposition=>'inline', :type=>'application/pdf')
      }
    end
  end

  def piurichiesti
    @pagetitle="PAC - Lettori"
    @clavis_manifestations=ClavisManifestation.piurichiesti
  end

  def ean_duplicati
    @pagetitle="PAC - Duplicati da eliminare"
    @sbct_titles = SbctTitle.lista_duplicati(params)
  end

  def view_users
    if can? :view_users, SbctTitle
      @users = SbctTitle.users
    else
      @users = []
    end
  end

  def new
    render text:'Inserimento titolo non abilitato', layout:true and return if SbctTitle.libraries_select(current_user).size == 0
    user_session[:sbct_titles_ids]=nil
    @pagetitle="PAC-IT (inserimento titolo)"
    # @sbct_title = SbctTitle.new
    @sbct_title = SbctTitle.new(params[:sbct_title])
    if SbctTitle.is_ean?(@sbct_title.titolo)
      @sbct_title.ean=@sbct_title.isbn=@sbct_title.titolo
      # @sbct_title.titolo="Nuovo titolo con ean #{@sbct_title.ean}"
      @sbct_title.titolo=""
    end
    respond_with(@sbct_title)
  end

  def create
    user_session[:sbct_titles_ids]=nil
    @sbct_title = SbctTitle.new(params[:sbct_title])
    @sbct_title.created_by = current_user.id
    @sbct_title.current_user = current_user
    @sbct_title.save
    respond_with(@sbct_title)
  end

  def destroy
    user_session[:sbct_titles_ids]=nil
    @sbct_title.save_before_delete(current_user.id)
    @sbct_title.destroy
    redirect_to sbct_titles_path
  end

  def index
    user_session[:tinybox] = [] if user_session[:tinybox].nil?
    if params[:tinybox]=='empty'
      user_session[:tinybox] = []
      redirect_to '/pac' and return
    end
    
    if params[:tinybox]=='unlink_lists'
      @sbct_title_ids = user_session[:tinybox]
    end
    
    if !params[:tinybox].blank?
      tinybox_ids = user_session[:tinybox]
    else
      tinybox_ids = nil
    end

    if params[:id_lista].blank?
      @pagetitle="PAC - HomePage "
    else
      @pagetitle="PAC - Titoli in #{SbctList.find(params[:id_lista]).to_label}"
    end
    @current_order = SbctOrder.find(user_session[:current_order]) if !user_session[:current_order].nil?

    if params[:check_boxes]!='N'
      @sbct_item = SbctItem.new
      @sbct_item.js_code = :switch_title
    end
    
    per_page = params[:per_page].blank? ? 200 : params[:per_page]
    @sql,@sbct_title,@sbct_list,@sbct_budgets,@sbct_budget=SbctTitle.sql_for_tutti(params,current_user,tinybox_ids)
    if params[:group_by].blank?
      if params[:items_per_libraries].blank?
        @sbct_titles = SbctTitle.paginate_by_sql(@sql, page:params[:page], per_page:per_page)
      else
        if current_user.email=='seba'
          render template:'sbct_items/per_libraries' and return
        else
          render text:'temporaneamente non disponibile', layout:true and return
        end
      end
    else
      @group_by=params[:group_by]
      render template:'sbct_titles/group_by'
      return
    end
    user_session[:current_sql]=@sql
    user_session[:current_params]=params
    user_session[:sbct_titles_ids]=@sbct_titles.collect {|i| i.id}
    user_session[:sbct_titles_ids] = user_session[:sbct_titles_ids].uniq
    user_session[:delivery_notes_mode]=nil
    respond_to do |format|
      format.html {
        if @sbct_titles.count==0 and !@sbct_title.titolo.nil? and [10,13].include?(@sbct_title.titolo.size)
          title = nil
          begin
            title=SbctTitle.new(ean:@sbct_title.titolo).find_by_ean_or_insert_from_clavis(current_user)
          rescue
            render text:"errore cercando #{@sbct_title.titolo}: #{$!}",layout:true and return
          end
          if title.class==SbctTitle
            redirect_to sbct_title_path(title) and return
          else
            flash[:notice] = title
          end
        end
        if @sbct_titles.size==1 and tinybox_ids.nil?
          title=SbctTitle.find(@sbct_titles[0].id)
          if params[:clavis_manifestation_id].to_i > 0 and title.manifestation_id.blank?
            title.manifestation_id=params[:clavis_manifestation_id].to_i
            title.save!
            # render text:"manifestation_id: #{params[:clavis_manifestation_id].to_i} - title: #{title.inspect}"
            # return
          end
          redirect_to sbct_title_path(title, norecurs:true, from_clavis:params[:from_clavis])
        else
          respond_with(@sbct_titles)
        end
      }
      format.csv {
        require 'csv'
        @sbct_titles = SbctTitle.find_by_sql(@sql)
        csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
          csv << ['autore','titolo','editore','collana','prezzo','isbn','anno']
          @sbct_titles.each do |r|
            csv << [r.autore,r.titolo,r.editore,r.collana,r.prezzo,r.isbn,r.anno]
          end
        end
        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=text.csv"
      }
    end
  end

  def edit
    render text:'Titolo non accessibile in modifica', layout:true if !@sbct_title.editable?(current_user) or SbctTitle.libraries_select(current_user).size == 0
    @pagetitle="PAC-MT-#{@sbct_title.id}"
  end

  def mass_edit
    @sbct_title = SbctTitle.new
    parent_id=params[:sbct_title][:parent_id].to_i
    kw = params[:sbct_title][:keywords].upcase
    title_ids=params[:title_ids].collect {|x| x.to_i}
    sql=[]
    sql << "BEGIN;"
    if parent_id>0
      sql << "UPDATE sbct_acquisti.titoli SET parent_id=#{parent_id} WHERE id_titolo IN (#{title_ids.join(',')});"
    end
    if !kw.blank?
      sql << "UPDATE sbct_acquisti.titoli SET keywords=#{@sbct_title.connection.quote(kw)} WHERE id_titolo IN (#{title_ids.join(',')});"
    end
    sql << "COMMIT;"
    sql = sql.join("\n")
    @sbct_title.connection.execute(sql)
    user_session[:sbct_titles_ids]=title_ids
    redirect_to sbct_title_path(title_ids[0])
  end

  def update
    @sbct_title = SbctTitle.find(params[:id])
    @sbct_title.current_user = current_user
    respond_to do |format|
      if @sbct_title.update_attributes(params[:sbct_title])
        @sbct_title.updated_by=current_user.id
        @sbct_title.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_title) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @sbct_title=SbctTitle.find(params[:id])

    begin
      @sbct_title.repair
    rescue
      render text:"errore #{$!}" and return if current_user.email=='seba'
    end
    @sbct_title.save if @sbct_title.changed?
    @pagetitle="PAC-T-#{@sbct_title.id}"
    @cr_title = SbctTitle.find_by_sql("select * from cr_acquisti.acquisti where id=#{@sbct_title.id}").first
    @current_order = SbctOrder.find(user_session[:current_order]) if !user_session[:current_order].nil?
    @current_budget = SbctBudget.find(user_session[:current_budget]) if !user_session[:current_budget].nil?
    @sbct_event = user_session[:sbct_event] if !user_session[:sbct_event].nil?

    # @sbct_clavis_libraries = @sbct_title.sbct_clavis_libraries
    if !user_session[:current_list].nil?
      @current_list = SbctList.find(user_session[:current_list]) 
      if !params[:toggle_list].blank?
        if @sbct_title.sbct_lists.include?(@current_list)
          @sbct_title.sbct_lists.delete(@current_list)
        else
          # @sbct_title.sbct_lists << @current_list
          @sbct_title.add_to_sbct_list(@current_list.id,current_user.id)
        end
      end
    end
    @esemplari_presenti_in_clavis = @sbct_title.esemplari_presenti_in_clavis
  end

  def insert_item
    supplier_id = nil
    if !user_session[:current_library].nil?
      budget_id = params[:budget_id].to_i
      if budget_id==0
        library_id = user_session[:current_library]
        if @sbct_title.reparto=='RAGAZZI'
          cond = "label ~* 'ragazzi'"
        else
          cond = "not label ~* 'ragazzi'"
        end
        sql = "select distinct budget_id,supplier_id from public.pac_budgets where not locked and library_id=#{library_id} and supplier_id is not null and #{cond}"
        res = @sbct_title.connection.execute(sql).first
        if res.nil?
          budget_id = nil
          supplier_id = nil
        else
          budget_id = res['budget_id'].to_i
          supplier_id = res['supplier_id'].to_i
        end
      else
        (
          b = SbctBudget.find(budget_id)
          library_id = b.clavis_budget.library_id
        )
      end
    else
      budget = SbctBudget.find(user_session[:current_budget])
      budget_id = budget.id
      library_id = budget.clavis_libraries.first.id
    end
    item = SbctItem.new(id_titolo:@sbct_title.id,
                        library_id:library_id,
                        budget_id:budget_id,
                        supplier_id:supplier_id,
                        created_by:current_user.id,
                        order_status:'S')
    if current_user.role?('AcquisitionLibrarian') and current_user.clavis_libraries.collect {|l| l.library_id if l.library_id==item.library_id}.compact.size > 0
      item.strongness=1
      item.qb = true
    else
      item.qb = false
    end
    item.save
    redirect_to sbct_title_path
  end

  def add_user
    if request.method == 'POST'
      roles = []
      roles << Role.find_by_name('ClavisItemSearch').id
      roles << Role.find_by_name('AcquisitionLibrarian').id
      User.add_clavis_librarian(params[:user_id], roles)
      redirect_to view_users_sbct_titles_path
    end
  end

  def edit_user
    @user = SbctUser.find(params[:user_id])
  end

  def toggle_tinybox_items
    ids = params[:title_ids]
    tb_ids = user_session[:tinybox]
    added = Array.new
    removed = Array.new
    if params[:op]=='attiva'
      ids.split(',').each do |e|
        id = e.to_i
        user_session[:tinybox] << id
        added << id
      end
    else
      ids.split(',').each do |e|
        id = e.to_i
        user_session[:tinybox].delete(id);
        removed << id
      end
    end
    user_session[:tinybox] = user_session[:tinybox].uniq
    render json:{added:added, removed:removed, tinybox_ids_cnt:user_session[:tinybox].size}
  end

  def add_or_remove_from_tinybox
    id = params[:id].to_i
    user_session[:tinybox] = [] if user_session[:tinybox].nil?
    if request.method == 'POST'
      operation = 'add'
      user_session[:tinybox] << id
      user_session[:tinybox] = user_session[:tinybox].uniq
    else
      operation = 'rm'
      user_session[:tinybox].delete(id)
    end
    render json:{tinybox_ids_cnt:user_session[:tinybox].size,id_titolo:id,op:operation}
  end
  
  def add_items_to_order
    budget = SbctBudget.find(user_session[:current_budget])
    order = SbctOrder.find(user_session[:current_order])
    copie = @sbct_title.sbct_items.collect{|i| i if i.order_status=='S' and i.supplier_id==order.supplier_id and i.budget_id==budget.id}.compact
    # render text:copie.size and return
    copie.each do |c|
      c.order_status='O'
      c.order_id=order.id
      c.save
    end
    # render text:copie.size and return
    redirect_to sbct_title_path
  end

  def add_to_list(sbct_list_id)
  end

  def upload
      if request.method=="POST"
      uploaded_io = params[:filename]
      if uploaded_io.nil?
        render :text=>'file_non_specificato', layout:true
      else
        target_filename = File.join('/home/seb/uploaded', uploaded_io.original_filename)
        File.open(target_filename, 'wb') do |file|
          file.write(uploaded_io.read)
        end
        begin
          sql_file = "/home/seb/load_report.sql"
          sql_data = SbctTitle.import_from_csv(target_filename,"sbct_acquisti.report_logistico",create_table=false,truncate_table=true)
          fd = File.open(sql_file, 'w')
          fd.write(sql_data)
          fd.write("update sbct_acquisti.report_logistico rl set id_titolo=t.id_titolo from sbct_acquisti.titoli t where t.ean=rl.codiceean and rl.id_titolo is null;\n");
          fd.close
          config   = Rails.configuration.database_configuration
          dbname=config[Rails.env]["database"]
          username=config[Rails.env]["username"]
          at_file = "/home/seb/at_load_report_user_#{current_user.email}.txt"
          fd = File.open(at_file,"w")
          fd.write("# Generato da SbctTitleController#upload - #{Time.now}\n\n")
          fd.write("LANG='en_US.UTF-8'\n")
          fd.write(%Q{/usr/bin/psql --no-psqlrc -d #{dbname} #{username} -f #{sql_file}\n})
          fd.close
          cmd = "at -f #{at_file} now + 1 minute"
          Kernel.system(cmd)
        rescue
          render text:"<pre>#{$!}</pre>", layout:'sbct' and return
        end
        redirect_to sbct_titles_path
      end
    else
    end
  end

  def delivery_notes
    @pagetitle="PAC - Bolle di consegna"
    if !params[:dnoteid].blank?
      params[:dataonly]='true'
      @sql,@sbct_title,@sbct_list,@sbct_budgets,@sbct_budget=SbctTitle.sql_for_tutti({dnoteid:params[:dnoteid],order:'9'},current_user)
      # render text:"<pre>#{@sql}</pre>" and return
      @sbct_titles = SbctTitle.paginate_by_sql(@sql, page:params[:page], per_page:200)
      user_session[:current_sql]=@sql
      user_session[:delivery_notes_mode] = true
      user_session[:sbct_titles_ids]=@sbct_titles.collect {|i| i.id}
      user_session[:sbct_titles_ids] = user_session[:sbct_titles_ids].uniq
    end
    respond_to do |format|
      format.html
      format.pdf {
        delivery_date,delivery_note = params[:dnoteid].split('|')
        heading = "Bolla #{delivery_note} del #{delivery_date.to_date}"
        if @sbct_titles.size > 0
          cliente = @sbct_titles.first.order_details.first.cliente
        else
          cliente = ''
        end

        @sbct_titles.define_singleton_method(:titolo_elenco) do
          [heading,cliente]
        end
        numerobolla = delivery_note.to_i
        @sbct_titles.define_singleton_method(:numerobolla) do
          numerobolla
        end

        print_mode = params[:mode]=='striscioline' ? 'striscioline' : ''
        @sbct_titles.define_singleton_method(:print_mode) do
          print_mode
        end

        # raise "debug bolla di consegna - #{@sbct_titles.first.attributes}"
        # raise "debug bolla di consegna - #{@sbct_titles[43].id}"
        filename="#{heading}.pdf"
        lp=LatexPrint::PDF.new('delivery_note', @sbct_titles, false)
        send_data(lp.makepdf, :filename=>filename,:disposition=>'inline', :type=>'application/pdf')
      }
    end
  end

  def add_to_library
    @clavis_library=ClavisLibrary.find(params[:library_id])
    @sbct_title=SbctTitle.find(params[:id])
    @sbct_list = SbctList.find(params[:id_lista])
    @sbct_budget = @sbct_list.budget(@clavis_library.id)
    # @error="Per #{@clavis_library.id} budget #{@sbct_budget.id}"
    @sbct_supplier = @sbct_budget.sbct_supplier
    if @sbct_supplier.nil?
      # @error="La lista d'acquisto #{@sbct_list.to_label} non ha fornitore associato - Budget: #{@sbct_budget.label}"
      supplier_id=@current_supplier
    else
      supplier_id=@sbct_supplier.id
    end
    if current_user.clavis_libraries.include?(@clavis_library)
      if !@sbct_budget.nil? and !current_user.sbct_budgets.include?(@sbct_budget) 
        @error="Il budget richiesto, relativo a #{@sbct_budget.clavis_budget.clavis_library.shortlabel.strip}, non è tra quelli su cui puoi operare"
      end
    else
      @error="La biblioteca richiesta non è tra quelle su cui puoi operare"
    end
    if @sbct_budget.nil?
      sql = "select b.* from sbct_acquisti.budgets b join sbct_acquisti.l_budgets_libraries using(budget_id) where not b.locked and clavis_library_id=#{@clavis_library.library_id};"
      @sbct_budget=SbctBudget.find_by_sql(sql).first
    end
        
    if @error.nil?
      if params[:checked]=='true'
        @sbct_title.connection.execute("insert into sbct_acquisti.copie (id_titolo, supplier_id, budget_id, library_id, created_by, order_status) values (#{@sbct_title.id},#{supplier_id},#{@sbct_budget.id},#{@clavis_library.id},#{current_user.id},'S')");
        @sbct_title.sbct_items.collect {|r| r.save}
      else
        if current_user.email=='giotor'
          @sbct_title.connection.execute("delete from sbct_acquisti.copie where id_titolo=#{@sbct_title.id} and library_id=#{@clavis_library.id} and budget_id=#{@sbct_budget.id} and order_status!='A'");
        else
          @sbct_title.connection.execute("UPDATE sbct_acquisti.copie SET order_status=null,budget_id=null where id_titolo=#{@sbct_title.id} and library_id=#{@clavis_library.id} and budget_id=#{@sbct_budget.id} and order_status!='A'");
        end
      end
    end
    # @sbct_list_totale = SbctList.totale_ordine(@sbct_title.sbct_list_ids)
    # @sbct_list_totale = @sbct_list.totale_ordine
    respond_to do |format|
      format.html {
      }
      format.js {
      }
    end
  end


  
end
